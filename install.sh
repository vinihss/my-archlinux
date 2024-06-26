#!/bin/bash

# Nome do usuário principal
USER_NAME="vinicius"
PASSWORD="minhasenha"
HOSTNAME="meuhost"
DISK="/dev/sdX"  # Substitua por seu disco (por exemplo, /dev/sda)
GITHUB_USER="vinihss"
GIST_NAME="archlinux_personal_add_install.sh"

# Verificar se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root"
   exit 1
fi

# Atualiza o relógio do sistema
timedatectl set-ntp true

# Particionamento do disco (exemplo usando parted)
parted $DISK mklabel gpt
parted $DISK mkpart primary ext4 1MiB 100%
mkfs.ext4 ${DISK}1
mount ${DISK}1 /mnt

# Instalação do sistema base
pacstrap /mnt base linux linux-firmware

# Gerar o fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot para o novo sistema
arch-chroot /mnt /bin/bash <<EOF

# Definir o fuso horário
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Localização
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Definir hostname e hosts
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Definir senha root
echo "root:$PASSWORD" | chpasswd

# Instalar e configurar o GRUB
pacman --noconfirm -S grub
grub-install --target=i386-pc $DISK
grub-mkconfig -o /boot/grub/grub.cfg

# Criar usuário e definir senha
useradd -m $USER_NAME
echo "$USER_NAME:$PASSWORD" | chpasswd
usermod -aG wheel,audio,video,optical,storage $USER_NAME

# Habilitar sudo para o usuário
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Atualizar o sistema
echo "Atualizando o sistema..."
pacman -Syu --noconfirm

# Instalar pacotes essenciais
echo "Instalando pacotes essenciais..."
pacman -S --noconfirm jack2 qjackctl ardour pulseaudio-jack cadence calf helm

# Instalar pacotes AUR
echo "Instalando pacotes AUR..."
# Instala yay se não estiver instalado
if ! command -v yay &> /dev/null; then
    echo "Instalando yay (AUR helper)..."
    sudo -u $USER_NAME bash -c 'git clone https://aur.archlinux.org/yay.git /home/$USER_NAME/yay && cd /home/$USER_NAME/yay && makepkg -si --noconfirm'
fi

sudo -u $USER_NAME yay -S --noconfirm reaper-bin bitwig-studio 

# Adicionar usuário ao grupo audio
echo "Adicionando $USER_NAME ao grupo audio..."
usermod -aG audio $USER_NAME

# Configurar limites de tempo real
echo "Configurando limites de tempo real..."
cat <<EOL >> /etc/security/limits.conf
@audio   -  rtprio     95
@audio   -  memlock    unlimited
EOL


# Verificar se está no Arch Linux e executar o script adicional do GitHub
if [ -f /etc/arch-release ]; then
    echo "Baixando e executando o script adicional do GitHub para Arch Linux..."
   # sudo -u $USER_NAME bash -c "curl -o /home/$USER_NAME/$GIST_NAME https://gist.githubusercontent.com/$GITHUB_USER/$GIST_NAME/raw && bash /home/$USER_NAME/$GIST_NAME"
else
    echo "Nehnhum script específico da distribuição para instalação"
fi



# Instalar kernel em tempo real (opcional)
echo "Instalando kernel em tempo real..."
pacman -S --noconfirm linux-rt linux-rt-headers

# Habilitar serviços
systemctl enable NetworkManager
systemctl enable sshd
# Adicione outros serviços conforme necessário

# Definir shell padrão para zsh
chsh -s /bin/zsh $USER_NAME

EOF

# Desmontar e reiniciar
umount -R /mnt
reboot

# Mensagem final
echo "Configuração concluída. Reinicie o sistema para aplicar todas as mudanças."
