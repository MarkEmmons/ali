# Initial Steps

```Bash
# Verify Boot-Mode
ls /sys/firmware/efi/efivars

# Verify Internet Connection
ping archlinux.org -c 4 > /dev/null

# Update System Clock
timedatectl set-ntp true
```

# Partition the Disks

```Bash
gdisk "/dev/${device}" <<< "n


+300M
ef00
n


+4G
8200
n




w
Y"
```

# Format the partitions

```Bash
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
```

# Install Base System

```Bash
# Install the essential packages
pacstrap /mnt base linux linux-firmware efibootmgr grub-bios grub-btrfs btrfs-progs sudo zsh #git stow parallel

# Generate the fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy iso zshrc to root
cp /etc/zsh/zshrc /mnt/root/.zshrc
```

Pause here to take a snapshot

```Bash
VBoxManage snapshot ALI take Chroot --description="Post genfstab, system is ready to be chrooted into" --live
```

# Chroot

```Bash
arch-chroot /mnt /bin/zsh

# Configure clock
[[ -f /etc/localtime ]] && rm /etc/localtime
ln -s /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc --utc

# Generate locales
sed 's|#en_US|en_US|' -i /etc/locale.gen
locale-gen

# Export locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG=en_US.UTF-8

# Add host
echo "Arch" > /etc/hostname

# Install Linux
sed '/^MODULES=/s|()|(btrfs)|' -i /etc/mkinitcpio.conf
mkinitcpio -p linux

# Install and configure grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Configure Users
ROOT="root"
USER="mark"
PASS="mark"

## Root
echo "root:$ROOT" | chpasswd
unset $ROOT
chsh -s /bin/zsh

## User
useradd -m -G wheel -s /bin/zsh $USER
cp /root/.zshrc /home/$USER/.zshrc
echo "$USER:$PASS" | chpasswd
unset $PASS
sed "s/^root ALL=(ALL) ALL/root ALL=(ALL) ALL\n$USER ALL=(ALL) ALL/" -i /etc/sudoers

# Enable dhcpcd
pacman --needed --noconfirm --noprogressbar -S dhcpcd
systemctl enable dhcpcd.service
```

Take another snapshot

```Bash
VBoxManage snapshot ALI take Base --description="Post chroot, base system with no gui" --live
```