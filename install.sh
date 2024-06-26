#!/bin/bash

# Função para solicitar valores do usuário
get_input() {
  read -p "Digite o nome do usuário principal: " USER_NAME
  read -sp "Digite a senha do usuário: " PASSWORD
  echo
  read -p "Digite o hostname: " HOSTNAME
  read -p "Digite o disco de destino (por exemplo, /dev/sda): " DISK
  read -p "Digite seu nome de usuário do GitHub: " GITHUB_USER
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

# Função para criar partições
create_partitions() {
  if [ "$BOOT_MODE" == "EFI" ]; then
    echo "Criando tabela de partição GPT no disco $DISK..."
    echo -e "o\nn\np\n1\n\n+512M\nt\n1\nn\np\n2\n\n+50G\nn\np\n3\n\n\nw" | fdisk $DISK

    echo "Formatando a partição ${DISK}1 como FAT32..."
    mkfs.fat -F32 ${DISK}1
  else
    echo "Criando tabela de partição DOS no disco $DISK..."
    echo -e "o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n+50G\nn\np\n3\n\n\nw" | fdisk $DISK

    echo "Formatando a partição ${DISK}1 como ext4..."
    mkfs.ext4 ${DISK}1
  fi

  echo "Formatando a partição ${DISK}2 como Btrfs..."
  mkfs.btrfs ${DISK}2

  echo "Formatando a partição ${DISK}3 como Btrfs..."
  mkfs.btrfs ${DISK}3

  echo "Montando a partição raiz ${DISK}2 em /mnt..."
  mount ${DISK}2 /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  umount /mnt

  mount -o subvol=@ ${DISK}2 /mnt
  mkdir -p /mnt/home
  mount -o subvol=@home ${DISK}2 /mnt/home

  echo "Montando a partição de boot ${DISK}1 em /mnt/boot..."
  mkdir -p /mnt/boot
  mount ${DISK}1 /mnt/boot
}

# Função para instalar o sistema base
install_base_system() {
  echo "Instalando o sistema base..."
  pacstrap /mnt base linux linux-firmware btrfs-progs
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Função para configurar o fuso horário
configure_time() {
  arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
EOF
}

# Função para configurar o locale
configure_locale() {
  arch-chroot /mnt /bin/bash <<EOF
echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
EOF
}

# Função para configurar o hostname
configure_hostname() {
  arch-chroot /mnt /bin/bash <<EOF
echo "$HOSTNAME" > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
EOF
}

# Função para configurar o initramfs
configure_mkinitcpio() {
  arch-chroot /mnt /bin/bash <<EOF
mkinitcpio -P
EOF
}

# Função para configurar o bootloader
configure_bootloader() {
  if [ "$BOOT_MODE" == "EFI" ]; then
    arch-chroot /mnt /bin/bash <<EOF
bootctl install
cat <<BOOT > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}2) rw
BOOT

echo "default arch" > /boot/loader/loader.conf
EOF
  else
    arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm grub
grub-install --target=i386-pc $DISK
grub-mkconfig -o /boot/grub/grub.cfg
EOF
  fi
}

# Função para definir a senha do root
set_root_password() {
  arch-chroot /mnt /bin/bash <<EOF
echo "Definindo senha root..."
echo root:$PASSWORD | chpasswd
EOF
}

# Função para criar um usuário
create_user() {
  arch-chroot /mnt /bin/bash <<EOF
useradd -m -G wheel -s /bin/bash $USER_NAME
echo $USER_NAME:$PASSWORD | chpasswd
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
EOF
}

# Função para instalar pacotes adicionais
install_additional_packages() {
  arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm git python python-pip nodejs npm yarn go openvpn terminator zsh firefox openssh neovim curl jq yay
EOF
}

# Função para configurar o zsh como shell padrão
set_default_shell() {
  arch-chroot /mnt /bin/bash <<EOF
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
  install_base_system
  configure_time
  configure_locale
  configure_hostname
  configure_mkinitcpio
  configure_bootloader
  set_root_password
  create_user
  install_additional_packages
  set_default_shell
  run_additional_script

  echo "Instalação concluída! Reinicie o sistema."
}

main
