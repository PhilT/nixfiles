require 'net/http'
require 'json'
require 'fileutils'
require 'uri'
require 'thor'

class Wallpaper < Thor
  API_URL = URI("https://wallhaven.cc/api/v1/search?sorting=random&q=lowlight&atleast=1920x1080")
  SAVE_DIR = '/data/pictures/wallpaper/'
  FILENAMES = ['wallpaper-left.jpg', 'wallpaper-right.jpg']

  desc "download [SCREEN]", "Download wallpaper from Wallhaven. SCREEN can be 'left' or 'right'"
  option :apply, type: :boolean, default: false, desc: "Apply wallpaper to sway"
  option :mnt, type: :string, default: "", desc: "Mount point"
  def download(screen = nil)
    puts "Downloading wallpapers..."
    data = fetch_json
    urls = random_wallpapers(data)
    download_wallpaper(urls.first, FILENAMES.first) if screen == 'left' || screen.nil?
    download_wallpaper(urls.last, FILENAMES.last) if screen == 'right' || screen.nil?
    update_sway_wallpaper if options[:apply]
  end

  private

  def configure_ssl(http)
    http.use_ssl = true
    http.cert_store = OpenSSL::X509::Store.new
    http.cert_store.set_default_paths
    http.cert_store.flags = 0  # Disable CRL checking
  end

  def fetch_json
    http = Net::HTTP.new(API_URL.host, API_URL.port)
    configure_ssl(http)

    response = http.get(API_URL.request_uri)
    json = JSON.parse(response.body)
    data = json && json["data"]
    raise "No wallpaper found" unless data&.any?
    data
  end

  def random_wallpapers(data)
    puts "Taking a sample from #{data.size} images"
    urls = data.sample(2).map { URI(it['path']) }

    raise "Not enough wallpapers found" if urls.count < 2

    urls
  end

  def download_wallpaper(url, filename)
    http = Net::HTTP.new(url.host, url.port)
    configure_ssl(http)

    response = http.get(url.path)

    path = File.join(options[:mnt], SAVE_DIR, filename)
    File.open(path, 'wb') { |file| file.write(response.body) }

    puts "Saved wallpaper to #{path}"
  end

  def update_sway_wallpaper
    `swaymsg output eDP-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill`
    `swaymsg output DP-2 background /data/pictures/wallpaper/wallpaper-left.jpg fill`
    `swaymsg output DP-3 background /data/pictures/wallpaper/wallpaper-right.jpg fill`
  end
end