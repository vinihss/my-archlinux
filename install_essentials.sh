#!/bin/bash

# Verificar se o script está sendo executado no Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "Este script é destinado apenas para Arch Linux."
    exit 1
fi

# Verificar se o script está sendo executado como o usuário correto
if [[ $EUID -eq 0 ]]; then
   echo "Este script não deve ser executado como root"
   exit 1
fi

# Instalar yay se não estiver instalado
if ! command -v yay &> /dev/null; then
    echo "Instalando yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
fi

# Instalar pacotes AUR
echo "Instalando pacotes AUR..."
yay -S --noconfirm reaper-bin bitwig-studio jetbrains-toolbox google-chrome brave-bin spotify postman-bin rocketchat-desktop nordvpn-bin
