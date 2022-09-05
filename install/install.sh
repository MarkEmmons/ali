# Verify Boot-Mode
ls /sys/firmware/efi/efivars

# Verify Internet Connection
ping archlinux.org -c 4 > /dev/null

# Update System Clock
timedatectl set-ntp true

# Partition the Disks
gdisk /dev/sda <<< "n


+300M
ef00
n


+4G
8200
n




w
Y"

# Format the partitions
mkfs.fat -F32 /dev/sda1

mkswap /dev/sda2

mkfs.btrfs -f /dev/sda3

# Create subvolumes
mount /dev/sda3 /mnt
pushd /mnt
btrfs subvolume create @
btrfs subvolume create @home
popd
umount /mnt

# Mount the filesystems
### Why doesn't space_cache work anymore?
mount -o noatime,compress-force=zstd,discard=async,subvol=@ /dev/sda3 /mnt

mkdir /mnt/{boot,home}

mount /dev/sda1 /mnt/boot
swapon /dev/sda2
mount -o noatime,compress-force=zstd,discard=async,subvol=@home /dev/sda3 /mnt/home

# Install the essential packages
pacstrap /mnt base linux linux-firmware efibootmgr grub-bios grub-btrfs btrfs-progs sudo zsh #git stow parallel

# Generate the fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy iso zshrc to root
cp /etc/zsh/zshrc /mnt/root/.zshrc

# Chroot
SCRIPT_ROOT=$(dirname $0)
arch-chroot /mnt /bin/zsh < $SCRIPT_ROOT/chroot/chroot.sh