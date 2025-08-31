require_relative "system"
require_relative "credentials"

class Disks
  include System
  include Zfs

  def initialize(machine, wipe: false, root: "/", credentials: Credentials.new, options: {})
    machines_config_path = File.join(APP_DIR, "config/machines.yml")
    if !File.exist?(machines_config_path)
      exit_with <<~HELP
        No config/machines.yml file found.
        Use config/machines.yml.example as a starting point.
      HELP
    end

    @machine = machine
    @machines = YAML.load_file(machines_config_path)
    @wipe = wipe # FIXME: Wipe might be related to root. As in, we'll only ever
    @root = root # wipe the disks if root is /mnt and vice versa
    @credentials = credentials
    @options = options
  end

  def disks = @machines[@machine]
  def more_than_one? = disks.size > 1

  def partition
    disks.each do |_, disk|
      rm_boot_entries disk["boot"]
      create_boot_disk disk["boot"]
      create_data_disk disk.dig("data", "device")
      create_pool disk["pool"]
      create_datasets disk["pool"]
      create_fat disk["boot"]
      create_directories disk.dig("pool", "directories")
    end
  end

  private

  def safe_mount(device, target, type = nil)
    if !mount_point?(target) || options[:dryrun]
      type = "-t zfs " if type == "zfs"
      sudo "mount #{type}#{device} #{target}"
    end
  end

  def mount_point?(target)
    run("mountpoint -q #{target}", handle_failure: true)
  end

  def rm_boot_entries(boot)
    return unless @wipe && boot&.dig("remove_entries")

    log "BOOT", "Removing boot entries"
    entries = run("efibootmgr")
    entries
      .split("\n")
      .filter { it.include?("Linux Boot Manager") }
      .each { run "efibootmgr -Bb #{it.sub(/Boot([0-9]+).*/, '\1')}" }
  end

  def create_boot_disk(boot)
    return unless @wipe && boot

    device, size = boot.values_at("device", "size")

    log "PART", "WARNING: This will destroy all your data!!!"
    wait "Press ENTER to repartition #{device}"

    log "PART", "Setup boot and primary partitions"
    sudo "sgdisk -Z #{device}" # Wipe partitions
    sudo "parted -s #{device} -- mklabel gpt"
    sudo "parted -s #{device} -- mkpart ESP fat32 0% #{size}"
    sudo "parted -s #{device} -- mkpart primary #{size} 100%"
    sudo "parted -s #{device} -- set 1 boot on"
    sudo "partprobe #{device}"
  end

  def create_data_disk(device)
    return unless @wipe && device

    log "PART", "WARNING: This will destroy all your data!!!"
    wait "Press ENTER to repartition #{device}"

    log "PART", "Setup data disk"
    sudo "sgdisk -Z #{device}" # Wipe partitions
  end

  def create_pool(pool)
    return unless pool

    name, partition, encryption = pool.values_at("name", "partition", "encryption")
    exists = in_zpool?(name)
    return if !@wipe && exists

    log "POOL", "Setup ZFS pool"
    create = exists ? "recreate" : "create"
    log "PART", "WARNING: This will destroy all your data!!!"
    wait "Press ENTER to #{create} zpool '#{name}'"

    if encryption == "on"
      password = "echo #{disks_password} | "
      options = " \
        -O encryption=on \
        -O keyformat=passphrase \
        -O keylocation=prompt"
    end

    run(
      password,
      "sudo zpool create -f",
      options,
      "-o", "ashift=12",
      "-O", "atime=off",
      "-O", "compression=lz4",
      "-O", "mountpoint=none",
      "-O", "acltype=posixacl",
      "-O", "xattr=sa",
      name,
      partition
    )
  end

  # Create a ZFS dataset and snapshot it in it's empty state
  # to be able to rollback for ephemeral storage.
  def create_datasets(pool)
    return unless pool
    datasets = pool.dig("datasets")
    return unless datasets

    log "DATASET", "Setup datasets: #{datasets.join(", ")}"

    datasets.each do |name|
      dataset = "#{pool["name"]}/#{name}"
      mountpoint = "#{@root}#{name}"
      mountpoint = @root if name == "root"

      if !run("zfs list")&.include?(dataset)
        run "zfs create -o mountpoint=legacy #{dataset}"
        run "zfs snapshot #{dataset}@blank"
      else
        log "DATASET", "#{dataset} exists. Skipping"
      end

      sudo "mkdir -p #{mountpoint}"
      safe_mount dataset, mountpoint, "zfs"
    end
  end

  def create_fat(boot)
    return unless boot

    boot_partition = boot.values_at("device", "partition").join("")
    if @wipe
      log "PART", "WARNING: This will destroy all your data!!!"
      wait "Press ENTER to format #{boot_partition}"
      sudo "mkfs.vfat -n boot #{boot_partition} > /dev/null"
    end

    sudo "mkdir -p #{@root}boot"
    safe_mount boot_partition, "#{@root}boot"
  end

  def create_directories(directories)
    return unless directories

    directories.each do |dir|
      sudo "mkdir -p #{@root}#{dir}"
    end
  end

  def disks_password
    @credentials.dig(:disks, :encryption_password)
  end
end