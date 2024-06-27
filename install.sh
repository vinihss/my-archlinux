#!/bin/bash

# Função para solicitar valores do usuário
get_input() {
  read -p "Digite o nome do usuário principal: " USER_NAME
  read -sp "Digite a senha do usuário: " PASSWORD
  echo
  read -p "Digite o hostname: " HOSTNAME
  read -p "Digite o disco de destino (por exemplo, /dev/sda): " DISK
  read -p "Digite seu nome de usuário do GitHub (para o script adicional): " GITHUB_USER
  read -p "Digite o nome do repositório (GitHub) com os scripts de instalação: " REPO_NAME
  read -p "Digite o nome do script de instalação adicional: " SCRIPT_NAME
}

# Função para detectar BIOS ou EFI
detect_boot_mode() {
  if [ -d /sys/firmware/efi ]; then
    BOOT_MODE="EFI"
  else
    BOOT_MODE="BIOS"
  fi
  echo "Modo de boot detectado: $BOOT_MODE"
}

# Função para criar e formatar partições
create_partitions() {
  if [ "$BOOT_MODE" == "EFI" ]; then
    echo "Criando tabela de partição GPT no disco $DISK..."
    parted -s $DISK mklabel gpt
    parted -s $DISK mkpart primary fat32 1MiB 512MiB
    parted -s $DISK set 1 esp on
    parted -s $DISK mkpart primary ext4 512MiB 100%
    mkfs.fat -F32 ${DISK}1
  else
    echo "Criando tabela de partição DOS no disco $DISK..."
    parted -s $DISK mklabel msdos
    parted -s $DISK mkpart primary ext4 1MiB 100%
    parted -s $DISK set 1 boot on
  fi
  mkfs.ext4 ${DISK}2
}

# Função para montar partições
mount_partitions() {
  mount ${DISK}2 /mnt
  mkdir -p /mnt/boot
  mount ${DISK}1 /mnt/boot
}

# Função para instalar o sistema base
install_base_system() {
  pacstrap /mnt base linux linux-firmware btrfs-progs
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Função para configurar o sistema (chroot)
configure_system() {
  arch-chroot /mnt /bin/bash <<EOF
# Configuração do fuso horário
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Configuração do locale
echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Configuração do hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Configuração do mkinitcpio
mkinitcpio -P

# Configuração do bootloader
if [ "$BOOT_MODE" == "EFI" ]; then
  bootctl install
  cat <<BOOT > /boot/loader/entries/arch.conf
  title Arch Linux
  linux /vmlinuz-linux
  initrd /initramfs-linux.img
  options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}2) rw
  BOOT
  echo "default arch" > /boot/loader/loader.conf
else
  pacman -S --noconfirm grub
  grub-install --target=i386-pc $DISK
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# Definição de senha root
echo "root:$PASSWORD" | chpasswd

# Criação de um usuário
useradd -m -G wheel -s /bin/bash $USER_NAME
echo "$USER_NAME:$PASSWORD" | chpasswd
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers

# Instalação de pacotes adicionais, incluindo GNOME
pacman -S --noconfirm gnome gnome-extra gdm networkmanager openssh zsh git python python-pip nodejs npm yarn go terminator firefox neovim curl jq yay

# Habilitação de serviços
systemctl enable gdm
systemctl enable NetworkManager
systemctl enable sshd

# Configuração do zsh como shell padrão
chsh -s /bin/zsh $USER_NAME
EOF
}

# Função para clonar repositório do GitHub e executar script adicional
run_additional_script() {
  arch-chroot /mnt /bin/bash <<EOF
cd /home/$USER_NAME
sudo -u $USER_NAME git clone https://github.com/$GITHUB_USER/$REPO_NAME.git
cd $REPO_NAME
sudo -u $USER_NAME bash $SCRIPT_NAME
EOF
}

# Função principal
main() {
  get_input
  detect_boot_mode
  create_partitions
  mount_partitions
  install_base_system
  configure_system
  run_additional_script

  echo "Instalação concluída! Reinicie o sistema."
}

main
