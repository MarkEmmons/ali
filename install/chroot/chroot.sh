#!/bin/bash

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