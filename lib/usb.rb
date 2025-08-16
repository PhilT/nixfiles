module Usb
  def self.write(device)
    exit_with "No device specified" if device.nil?
    device1 = "/dev/#{device}1"
    device2 = "/dev/#{device}2"

    log "USB", "Unmounting USB stick"
    sudo "umount #{device1}" if File.exist?(device1)
    sudo "umount #{device2}" if File.exist?(device2)
    log "USB", "Writing ISO"
    sudo "dd if=$(ls result/iso/*.iso) of=/dev/#{device} bs=1M status=progress"
    log "USB", "Unmounting"
    sleep 2
    sudo "umount #{device1}" if File.exist?(device1)
    sudo "umount #{device2}" if File.exist?(device2)
    log "USB", "Done"
  end
end