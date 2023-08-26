machine=$1
nixos_dir=$2
dryrun=$3

source ./commands.sh
source ./common.env
source ./$machine.env

lvm_partition=${ssd}p2

STATE "COPY" "Copy config"
RUN "sudo cp ./bootstrap.nix $nixos_dir"
RUN "sudo cp ./common.nix $nixos_dir"
RUN "sudo cp ./$machine.nix $nixos_dir/configuration.nix"
RUN "sudo sed -i 's|USER_PASSWORD|$user_password|' $nixos_dir/bootstrap.nix"
RUN "sudo sed -i 's|LVM_PARTITION|$lvm_partition|' $nixos_dir/bootstrap.nix"

