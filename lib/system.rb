require "open3"
module System
  ROOT_DIR = Dir.pwd

  @@state = "BOOT"

  def log(section, message, newline: true)
    return if options[:log] == false
    @@state = section

    section = "[#{section.upcase.ljust(10)}] " if section
    section = " " * 13 if section.nil?
    print "#{section}#{message}#{newline ? "\n" : ""}"
  end

  def exit_with(message)
    log "ERROR", message
    exit 1
  end

  # show: If true, prints the stdout
  # dryrun: Allows callers to override the dryrun option for non-mutating commands
  # handle_failure: If true, doesn't exit but returns the exit code
  # use_system: If true, run the command using system instead of Open3.This is
  #             used by nixx to run nixos-rebuild commands which output progress.
  #
  # Returns nil if the command is unknown
  # Returns false if the command failed
  # Returns stdout if the command succeeded
  def run(*args, show: false, dryrun: options[:dryrun], handle_failure: false, use_system: false)
    cmd = args.join(" ")
    log @@state, cmd
    success = false

    if dryrun
      success = true
    elsif use_system
      success = system(cmd)
      exit_code = $CHILD_STATUS.exitstatus
    else
      begin
        stdout, stderr, status = Open3.capture3(cmd)
        success = status.success?
        exit_code = status.exitstatus
      rescue Errno::ENOENT => e
        success = nil
      end
    end

    if dryrun || success
      log @@state, stdout if show
      stdout
    elsif handle_failure
      success
    else
      log "FAIL", cmd
      log nil, "Exit code: #{exit_code}"
      log nil, "Result: #{stdout}" if stdout
      log nil, "Errors: #{stderr}" if stderr
      log "HELP", "If this was a nixos-<command> error, check prefix/nix/var/log/nix"
      exit exit_code
    end
  end

  # Run command as sudo if we aren't root.
  # Accepts the same arguments as run with the addition of a `dir:` argument which
  # is the directory to run the command in.
  def sudo(*args, dir: nil, **kwargs)
    # When run from nixos-enter we don't need sudo
    @sudo ||= `whoami`.strip == "root" ? nil : "sudo"

    cd = dir ? "cd #{dir} && " : nil
    cmd = args.prepend(cd, @sudo).compact
    run(cmd, **kwargs)
  end

  def wait(message)
    log @@state, message if message
    return if dryrun

    gets
  end
end