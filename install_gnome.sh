#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the system
echo "Updating the system..."
sudo pacman -Syu --noconfirm

# Install GNOME and extra GNOME packages
echo "Installing GNOME and extra packages..."
sudo pacman -S --noconfirm gnome gnome-extra

# Enable GDM to start at boot
echo "Enabling GDM (GNOME Display Manager) to start at boot..."
sudo systemctl enable gdm

# Start GDM immediately
echo "Starting GDM..."
sudo systemctl start gdm

# Install GNOME Tweaks tool
echo "Installing GNOME Tweaks..."
sudo pacman -S --noconfirm gnome-tweaks

# Install GNOME Software for package management
echo "Installing GNOME Software..."
sudo pacman -S --noconfirm gnome-software-packagekit-plugin

# Install GNOME Shell Extensions
echo "Installing GNOME Shell Extensions..."
sudo pacman -S --noconfirm gnome-shell-extensions

# Install additional themes and icon packs
echo "Installing additional themes and icon packs..."
sudo pacman -S --noconfirm arc-gtk-theme papirus-icon-theme

# Print completion message
echo "GNOME installation and configuration completed."
echo "You can now log in to your GNOME desktop environment."

# Reminder to run GNOME Tweaks for customization
echo "To further customize your GNOME desktop, use GNOME Tweaks by running 'gnome-tweaks'."
