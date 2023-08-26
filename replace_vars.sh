machine=$1
path_to_nixos_config=$2

source ./common.env
source ./$machine.env
lvm_partition=${ssd}p2

sed -i "s|USER_PASSWORD|$user_password|" $path_to_nixos_config
sed -i "s|LVM_PARTITION|$lvm_partition|" $path_to_nixos_config

