module System
  ROOT_DIR = File.expand_path(File.join(__dir__, ".."))

  def log(section, message)
    puts "[#{section.upcase.ljust(10)}] #{message}"
  end

  def exit_with(message)
    log "ERROR", message
    exit 1
  end

  def sudo(cmd, return_output: false)
    @sudo ||= `whoami`.strip == "root" ? "" : "sudo " # When run from nixos-enter we don't need sudo
    run("#{@sudo}#{cmd}", return_output:)
  end

  def run(cmd, return_output: false)
    if return_output
      `#{cmd}`
    else
      system(cmd)
    end
  end
end