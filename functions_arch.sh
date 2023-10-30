#!/bin/bash

# Color variables
orange_color="\033[0;33m"
green_color="\033[1;32m"
red_color="\033[37;41m"
blue_backround="\033[1;44m"
reset_color="\033[0m"


# Installation steps functions
#1 Questions for custom variables
function custom_questions { 

echo -e "$orange_color[INFO] Set up your account.$reset_color"
read -p "Choose a name for the new user: " user_name
read -p "Choose a password for $user_name: " user_pass # sa adaug flag sa nu se vada parola cand o scriu si sa rescrie parola
echo -e "${green_color}Script is running...$reset_color"

clear

if [[ "$install_option" == "2" ]]
then

    echo -e "$orange_color[INFO] Set up your time zone.$reset_color"
    read -p "Choose your city: " time_city # sa ia automat orasul potrivit daca ai gresit o litera
    read -p "Choose you region: " time_region

    clear

    echo -e "$orange_color[INFO] Choose the disk you want to partition and the size of the partitions (GPT only).$reset_color"
    sfdisk -l
    read -p "
Choose the disk you want to partition: " choose_disk
    read -p "
Choose the size of the swap partition (xM / xG): " choose_swap_size
    read -p "
Choose the size of the root partition (xM / xG): " choose_root_size

    clear

else

    sleep 1

fi

}


#2 Verify the boot mode (efi)
function verify_efi {

if [[ "$install_option" == "1" ]]
then
    if ls /sys/firmware/efi > /dev/null
    then
        echo "efivars found! Boot mode is prepared!" >> /dev/null
    else
        echo -e "$red_color[WARNING] efivars not found!$reset_color"
        exit
    fi
elif [[ "$install_option" == "2" ]]
then
    echo -e "$orange_color[INFO] Check efivars.$reset_color"
    if ls /sys/firmware/efi > /dev/null
    then
        echo -e "$green_color[DONE] efivars found! Boot mode is prepared!$reset_color"
    else 
        echo -e "$red_color[WARNING]efivars not found!$reset_color"
        exit
    fi
fi

}


#3 Check the internet connection
function check_internet {

if [[ "$install_option" == "1" ]]
then
    if ping -c 3 archlinux.org > /dev/null
    then
        echo "Internet is working properly!" >> /dev/null
    else 
        echo -e "$red_color[WARNING] No internetion connection!$reset_color"
        exit
    fi
    elif [[ "$install_option" == "2" ]]
    then
        echo -e "$orange_color[INFO] Connect to archlinux.org.$reset_color"
        if ping -c 3 archlinux.org > /dev/null
        then
            echo -e "$green_color[DONE] Internet is working properly!$reset_color"
        else 
            echo -e "$red_color[WARNING]No internetion connection!$reset_color"
            exit
    fi
fi

}


#4 Update the system clock
function upd_systclk {

if [[ "$install_option" == "1" ]]
then

    timedatectl

elif [[ "$install_option" == "2" ]]
then

    echo -e "$orange_color[INFO] Update the system clock.$reset_color"
    timedatectl
    echo -e "$green_color[DONE] The system clock has been updated!$reset_color"

fi

}


#5 Partition, format, mount the disks and generate fstab
function conf_disks {

if [[ "$install_option" == "1" ]]
then

sfdisk /dev/sda<<EOF
label: gpt
device: $choose_disk
size= 500M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,
size= 1024M, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F,
type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709,
EOF

mkfs.ext4 /dev/sda3	
mkswap /dev/sda2
mkfs.fat -F 32 /dev/sda1

mount /dev/sda3 /mnt 
mount --mkdir /dev/sda1 /mnt/boot 
swapon /dev/sda2

elif [[ "$install_option"=="2" ]]
then

sfdisk $choose_disk<<EOF
label: gpt
device: $choose_disk
size= 500M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,
size= $choose_swap_size, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F,
type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709,
EOF
sleep 5
clear

echo -e "$orange_color[INFO] Partition the disks.$reset_color"
sfdisk $choose_disk -l 
echo -e "
$green_color[DONE] The disks have been partitioned using the UEFI layout with GPT and following the recommended sizes! The table above shows the disk partitions.$reset_color"
sleep 5
clear

echo -e "$orange_color[INFO] Format the partitions.$reset_color"
mkfs.ext4 ${choose_disk}"3"
echo -e "$green_color[DONE] The root partition has been formatted to EXT4!$reset_color"
mkswap ${choose_disk}"2"
echo -e "$green_color[DONE] The swap partition has been initialized!$reset_color"
mkfs.fat -F 32 ${choose_disk}"1"
echo -e "$green_color[DONE] The EFI system partition has been formatted to FAT32!$reset_color"
sleep 5
clear

echo -e "$orange_color[INFO] Mount the file systems.$reset_color"
mount ${choose_disk}"3" /mnt 
echo -e "$green_color[DONE] The root partition has been mounted to /mnt!$reset_color"
mount --mkdir "${choose_disk}1" /mnt/boot
echo -e "$green_color[DONE] The EFI system partition has been mounted to /mnt/boot!$reset_color"
swapon ${choose_disk}"2"
echo -e "$green_color[DONE] The swap partition has been enabled!$reset_color"

fi

}


#6 Configure the system
#6.1 timezone
function set_timezone
{
if [[ "$install_option" == "1" ]]
then

ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime 
hwclock --systohc

elif [[ "$install_option"=="2" ]]
then

ln -sf /usr/share/zoneinfo/$1/$2 /etc/localtime 
hwclock --systohc

fi

}


#6.2 localization
function conf_localization {

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo “LANG=en_US.UTF-8” >> /etc/locale.conf

}


#6.3 add new user
function add_user {

useradd -m -g users -G wheel $1
passwd $1<<PASSWORD
$2
$2
PASSWORD

sed -i '/^# %wheel ALL=(ALL:ALL) ALL$/s/.*/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

}


#7 install grub
function install_grub {

mkdir /boot/efi
if [[ "$install_option" == "1" ]]
then
    mount /dev/sda1 /boot/efi
elif [[ "$install_option" == "2"  ]]
then
    mount $1 /boot/efi
fi
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
if ls /boot/grub | grep -q "locale"; then
echo "/etc/grub/locale found!" >> /dev/null
else 
    echo -e "=================================================
    /etc/grub/locale not found!
    ================================================="
    exit
fi
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo	
grub-mkconfig -o /boot/grub/grub.cfg

}


#8 Install graphical usr interface (gnome)
function install_gui {

if [[ "$install_option" == "1" ]]
then

pacman -S gnome<<GNOME
1-56
1
1
1
yes
GNOME

pacman --noconfirm -S gnome-tweaks

elif [[ "$install_option" == "2"  ]]
then

pacman -S gnome<<GNOME
1-56
1
1
1
yes
GNOME
pacman --noconfirm -S gnome-tweaks

fi

}


#9 Enable services
function enable_services {

systemctl enable systemd-timesyncd #synchronize clock
systemctl enable sshd 
systemctl enable NetworkManager
systemctl enable gdm #gnome

}

# Steps to be made in chroot, in the express installation (non-customizable)
function chroot_steps {

#a timezone
set_timezone

#b localization
conf_localization

#c configure network
echo “myhostname” >> /etc/hostname

#d add new user
add_user $user_name $user_pass

#e configure grub
install_grub

#f Install graphical user interface (gnome)
install_gui

#g Enable services
enable_services

}

########################################################################################################################################################

# Function for express installation (non-customizable)
function express_install_arch {
 
echo -e "
${blue_backround}You have chosen the express installation (non-customizable) of Arch Linux!$reset_color

"

custom_questions


#1 Verify the boot mode (efi)
verify_efi


#2 Check the internet connection
check_internet


#3 Update the system clock
upd_systclk


#4 Partition, format and mount the disks
conf_disks


#5 Install essential packages
pacstrap -K /mnt --noconfirm base linux linux-firmware networkmanager openssh grub efibootmgr dosfstools os-prober mtools xorg-server


#6 Configure the system
#6.1 Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# It allows chroot to call functions
cp ./functions_arch.sh /mnt

#6.2 chroot
arch-chroot /mnt /bin/bash -- <<CHROOT
source ./functions_arch.sh
chroot_steps
CHROOT


echo -e "\033[1;44mInstallation has finished! If you haven't recieved any errors so far, you may reboot your system and you should be able to use Arch Linux!$reset_color"

} 

##################################################################################################################################################################

# Function for custom installation 
function custom_install_arch {
    
echo -e "
${blue_backround}You have chosen the custom installation of Arch Linux!$reset_color"
echo -e "${green_color}Script is running...$reset_color"
sleep 5
clear


custom_questions


#1 Verify the boot mode (efi)
verify_efi
sleep 5
clear

#2 Check the internet connection
check_internet
sleep 5
clear


#3 Update the system clock
upd_systclk
sleep 5
clear


#4 Configure the disks
conf_disks
sleep 5
clear


#5 Install essential packages
echo -e "$orange_color[INFO] Install essential packages (base, linux, linux-firmware, ssh, sudo, grub and Window system (xorg system)).$reset_color"
sleep 3

pacstrap -K /mnt --noconfirm base linux linux-firmware networkmanager openssh sudo grub efibootmgr dosfstools os-prober mtools xorg-server 

echo -e "$green_color[DONE] The essential packages (base, linux, linux-firmware, ssh, sudo, grub and Window system (xorg system)) have been installed!$reset_color"
sleep 5
clear


#6 Configure the system
#6.1 Generate fstab
echo -e "$orange_color[INFO] Configure the system.
[INFO] Generate a fstab file and save it to /mnt/etc/fstab.$reset_color"
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "$green_color[DONE] The fstab file has been generated and save to /mnt/etc/fstab!$reset_color"
sleep 5
clear

# It allows chroot to call functions
cp ./functions_arch.sh /mnt

#6.2 chroot
arch-chroot /mnt /bin/bash -- <<CHROOT
source ./functions_arch.sh

echo -e "$orange_color[INFO] Set time zone.$reset_color"

set_timezone $time_region $time_city

echo -e "$green_color[DONE] The time was set for $time_city, $time_region!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Generate the locales and set LANG variable.$reset_color"

conf_localization

echo -e "$green_color[DONE] The locales have been generated and the LANG variable has been set!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Create the hostname file.$reset_color"

echo “myhostname” >> /etc/hostname

echo -e "$green_color[DONE] The hostname file has been created!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Add new user, set up a password and add the user to group wheel.$reset_color"

add_user $user_name $user_pass

echo -e "$green_color[DONE] New user $user_name has been created, the password has been set and the user has been added to group wheel!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Install grub.$reset_color"
sleep 2

install_grub ${choose_disk}1

echo -e "$green_color[DONE] grub has been succesfully installed!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Install graphical user interface (gnome).$reset_color"

install_gui

echo -e "$green_color[DONE] The grapchial user interface (gnome) has been succesfully installed!$reset_color"
sleep 5
clear


echo -e "$orange_color[INFO] Enable services (clock synchronization, ssh, network manager and gnome).$reset_color"

enable_services
CHROOT

echo -e "$green_color[DONE] Services (clock synchronization, ssh, network manager and gnome) have been enabled!$reset_color"
sleep 5
clear


echo -e "\033[1;44mInstallation has finished! If you haven't recieved any errors so far, you may reboot your system and you should be able to use Arch Linux!$reset_color"

}

######################################################################################################################################################################
