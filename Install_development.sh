#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Update the system
echo "Updating the system..."
pacman -Syu --noconfirm

# Install essential packages
echo "Installing essential packages..."
pacman -S --noconfirm git python python-pip nodejs npm yarn go openvpn terminator zsh firefox openssh neovim curl jq

# Install yay if not installed
if ! command -v yay &> /dev/null; then
    echo "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    cd ..
    rm -rf ~/yay
fi

# Install AUR packages
echo "Installing AUR packages..."
yay -S --noconfirm jetbrains-toolbox google-chrome brave-bin spotify postman-bin rocketchat-desktop nordvpn-bin

# Install general API development tools
echo "Installing general API development tools..."
yay -S --noconfirm insomnia

# Install tools for REST APIs
echo "Installing tools for REST APIs..."

# Node.js with Express
echo "Installing Node.js and Express..."
npm install -g express

# Python with Flask and Django
echo "Installing Python, Flask and Django..."
pip install flask django djangorestframework

# Go with Gin
echo "Installing Go and Gin..."
go get -u github.com/gin-gonic/gin

# PHP with Lumen and Laravel
echo "Installing PHP, Lumen and Laravel..."
sudo pacman -S --noconfirm php php-composer
composer global require laravel/lumen
composer global require laravel/installer

# Install tools for SOAP APIs
echo "Installing tools for SOAP APIs..."

# PHP with SOAP Extension
echo "Installing PHP SOAP extension..."
sudo pacman -S --noconfirm php-soap

# Python with Zeep
echo "Installing Zeep for Python..."
pip install zeep

# Java with Apache CXF
echo "Installing Apache CXF for Java..."
yay -S --noconfirm apache-cxf

# Install tools for gRPC APIs
echo "Installing tools for gRPC APIs..."

# gRPC for Python
echo "Installing gRPC for Python..."
pip install grpcio grpcio-tools

# gRPC for Go
echo "Installing gRPC for Go..."
go get -u google.golang.org/grpc
go get -u github.com/golang/protobuf/protoc-gen-go

# gRPC for Node.js
echo "Installing gRPC for Node.js..."
npm install -g @grpc/grpc-js @grpc/proto-loader

# Install Protobuf compiler
echo "Installing Protobuf compiler..."
sudo pacman -S --noconfirm protobuf

# Install Git and related tools
echo "Installing Git and related tools..."
sudo pacman -S --noconfirm git git-lfs lazygit
git lfs install

# Install GitKraken
echo "Installing GitKraken..."
yay -S --noconfirm gitkraken

# Install GitLab Runner
echo "Installing GitLab Runner..."
sudo pacman -S --noconfirm gitlab-runner
sudo systemctl enable gitlab-runner
sudo systemctl start gitlab-runner

# Bitwarden API variables
BW_CLIENT_ID="user.6692cfd7-818c-4174-8cab-b18500c81d4b"
BW_CLIENT_SECRET="4rJ1NKWXaUVfwNtzvIRLwSsiceaI2S"
BW_USERNAME="vinihss@gmail.com"
BW_PASSWORD="your_password"

# Get the access token
echo "Obtaining access token from Bitwarden..."
ACCESS_TOKEN=$(curl -s -X POST "https://api.bitwarden.com/identity/connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password&username=$BW_USERNAME&password=$BW_PASSWORD&client_id=$BW_CLIENT_ID&client_secret=$BW_CLIENT_SECRET" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to obtain access token."
    exit 1
fi

# Use the token to access the necessary data
echo "Accessing data from Bitwarden..."
ITEMS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "https://api.bitwarden.com/v1/items")

# Example: extract a specific password
# Adjust the jq query according to your data structure
PASSWORD=$(echo $ITEMS_JSON | jq -r '.items[] | select(.name=="NomeItemEspecifico") | .fields[] | select(.name=="password").value')

if [ -z "$PASSWORD" ]; then
    echo "Password not found."
    exit 1
fi

echo "Password retrieved: $PASSWORD"

echo "Installation and configuration completed."
