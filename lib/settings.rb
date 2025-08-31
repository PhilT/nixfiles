require_relative "system"

class Settings
  include System

  def initialize
    @settings = YAML.safe_load_file(File.join(APP_DIR, "config/settings.yml"))
  end

  def nixfiles_repo = @settings["repo"]
end
