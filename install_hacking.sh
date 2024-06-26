#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the system
echo "Updating the system..."
sudo pacman -Syu --noconfirm

# Install hacking tools
echo "Installing Nmap..."
sudo pacman -S --noconfirm nmap

echo "Installing Metasploit..."
sudo pacman -S --noconfirm metasploit

echo "Installing Wireshark..."
sudo pacman -S --noconfirm wireshark-qt

echo "Installing Aircrack-ng..."
sudo pacman -S --noconfirm aircrack-ng

echo "Installing John the Ripper..."
sudo pacman -S --noconfirm john

echo "Installing Hydra..."
sudo pacman -S --noconfirm hydra

echo "Installing Nikto..."
sudo pacman -S --noconfirm nikto

echo "Installing SQLmap..."
sudo pacman -S --noconfirm sqlmap

# Install Burp Suite from AUR
if ! command -v yay &> /dev/null
then
    echo "Installing yay (AUR helper)..."
    sudo pacman -S --noconfirm yay
fi

echo "Installing Burp Suite..."
yay -S --noconfirm burpsuite

echo "Installing OpenVAS..."
sudo pacman -S --noconfirm openvas

# Print completion message
echo "Hacking tools installation completed."
