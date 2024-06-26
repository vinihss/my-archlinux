#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Update the system
echo "Updating the system..."
sudo pacman -Syu --noconfirm

# Install OpenSSH
echo "Installing OpenSSH..."
sudo pacman -S --noconfirm openssh

# Enable and start the SSH daemon
echo "Enabling and starting SSH daemon..."
sudo systemctl enable sshd
sudo systemctl start sshd

# Install htop
echo "Installing htop..."
sudo pacman -S --noconfirm htop

# Install btop
echo "Installing btop..."
sudo pacman -S --noconfirm btop

# Install ncdu
echo "Installing ncdu..."
sudo pacman -S --noconfirm ncdu

# Install nano and vim
echo "Installing nano and vim..."
sudo pacman -S --noconfirm nano vim

# Install rsync
echo "Installing rsync..."
sudo pacman -S --noconfirm rsync

# Install Midnight Commander (mc)
echo "Installing Midnight Commander..."
sudo pacman -S --noconfirm mc

# Install Logrotate
echo "Installing Logrotate..."
sudo pacman -S --noconfirm logrotate

# Install OpenVPN and WireGuard
echo "Installing OpenVPN and WireGuard..."
sudo pacman -S --noconfirm openvpn wireguard-tools

# Print completion message
echo "Remote access tools installation completed."
