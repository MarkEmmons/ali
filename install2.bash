init(){

	ls /sys/firmware/efi/efivars > /dev/null || exit 1
	ping archlinux.org -c 2 > /dev/null || exit 1
	timedatectl set-ntp true
}

prepare_filesystem(){

	# Partition the Disks
	gdisk /dev/sda <<EOF
n


+300M
ef00
n


+2G
8200
n




w
Y
EOF

	# Format the partitions
	mkfs.fat -F 32 /dev/sda1
	mkswap /dev/sda2
	mkfs.ext4 /dev/sda3

	# Mount the filesystems
	mount /dev/sda3 /mnt
	mount --mkdir /dev/sda1 /mnt/boot
	swapon /dev/sda2
}

install_base() {

	# Install Base System
	reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
	pacstrap /mnt base linux linux-firmware grub efibootmgr vim zsh

	# Generate the fstab
	genfstab -U /mnt >> /mnt/etc/fstab

	# Use the zshrc included with the instllation medium as the default
	cp /etc/zsh/zshrc /mnt/etc/zsh/zshrc
}

# Chroot
chroot() {

	arch-chroot /mnt /bin/zsh <<EOF
# Configure clock
ln -s /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc --utc

# Generate locales
sed 's|#en_US|en_US|' -i /etc/locale.gen
locale-gen

# Export locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Add host
echo "Arch" > /etc/hostname

# Install Linux
mkinitcpio -p linux

# Install and configure grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set root password and exit
echo "root:asdf" | chpasswd
EOF

}

finish() {

	umount -R /mnt
	swapoff /dev/sda2
	read -n1 -rsp $'Press any key to reboot or Ctrl+C to stay in the installation shell...\n' < /dev/tty
	reboot
}

echo "Preparing to install Arch Linux"
init >init.log 3>&2 2>&1

echo "Formatting disk"
prepare_filesystem >prepare_filesystem.log 3>&2 2>&1

echo "Installing system"
install_base >install_base.log 3>&2 2>&1

echo "Chrooting into new system"
chroot >chroot.log 3>&2 2>&1

finish >finish.log 3>&2 2>&1
