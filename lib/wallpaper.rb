require 'net/http'
require 'json'
require 'fileutils'
require 'uri'
require 'thor'

class Wallpaper < Thor
  API_URL = URI("https://wallhaven.cc/api/v1/search?sorting=random&q=landscape,lowlight,space&atleast=1920x1080")
  SAVE_DIR = '/data/pictures/wallpaper/'
  FILENAMES = ['wallpaper-left.jpg', 'wallpaper-right.jpg']

  desc "download", "Download wallpaper from Wallhaven"
  option :apply, type: :boolean, default: false, desc: "Apply wallpaper to sway"
  def download(screen = nil)
    puts "Downloading wallpapers..."
    data = fetch_json
    urls = random_wallpapers(data)
    download_wallpaper(urls.first, FILENAMES.first) if screen == 'left' || screen.nil?
    download_wallpaper(urls.last, FILENAMES.last) if screen == 'right' || screen.nil?
    update_sway_wallpaper if options[:apply]
  end

  private

  def fetch_json
    response = Net::HTTP.get(API_URL)
    json = JSON.parse(response)
    data = json && json["data"]
    raise "No wallpaper found" unless data&.any?
    data
  end

  def random_wallpapers(data)
    urls = data.sample(2).map { URI(it['path']) }

    raise "Not enough wallpapers found" if urls.count < 2

    urls
  end

  def download_wallpaper(url, filename)
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      response = http.get(url.path)

      path = File.join(SAVE_DIR, filename)
      File.open(path, 'wb') { |file| file.write(response.body) }

      puts "Saved wallpaper to #{path}"
    end
  end

  def update_sway_wallpaper
    `swaymsg output eDP-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill`
    `swaymsg output DP-1 background /data/pictures/wallpaper/wallpaper-right.jpg fill`
    `swaymsg output HDMI-A-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill`
    `swaymsg output DP-3 background /data/pictures/wallpaper/wallpaper-right.jpg fill`
  end
end