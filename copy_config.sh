machine=$1
dryrun=$2

source ./commands.sh
source src/common.env
source src/$machine.env

lvm_partition=${ssd}p2

STATE "COPY" "Copy config"
RUN "cp src/minimal_template.nix src/minimal.nix"
RUN "sed -i 's|USER_NAME|$user_name|' src/minimal.nix"
RUN "sed -i 's|USER_FULLNAME|$user_full_name|' src/minimal.nix"
RUN "sed -i 's|USER_PASSWORD|$user_password|' src/minimal.nix"
RUN "sed -i 's|LVM_PARTITION|$lvm_partition|' src/minimal.nix"
