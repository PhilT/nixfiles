# TODO: Copied straight from the original build  bash script. Needs testing.

module Zfs
  def switch_to_key_based_encryption
    log "ZFS", "Switching to key-based encryption"
    pool_name = "dpool"
    zfs_keydir = "/root"
    zfs_keypath = "#{zfs_keydir}/.#{pool_name}.key"
    if in_zpool?(pool_name)
      if sudo("test -f #{zfs_keypath}")
        log pool_name, "#{zfs_keypath} exists"
      else
        log pool_name, "No #{pool_name} encryption key at #{zfs_keypath}. Creating and assigning"
        sudo("mkdir -p #{zfs_keydir}")
        sudo("chmod 700 #{zfs_keydir}")
        generate_key(zfs_keypath)
        change_key(pool_name, zfs_keypath)
      end
    else
      log pool_name, "No #{pool_name} pool. Skipping."
    end
  end

  def in_zpool?(pool_name)
    response = run("zpool list", handle_failure: true)
    response && response.include?(pool_name)
  end

  def generate_key(keyfile)
    sudo("dd if=/dev/urandom bs=32 count=1 of=#{keyfile}")
    sudo("chmod 400 #{keyfile}")
  end

  def change_key(pool_name, keyfile)
    keyfile = "file://#{keyfile}"
    sudo("zfs change-key -o keyformat=raw -o keylocation=#{keyfile} #{pool_name}")
  end
end