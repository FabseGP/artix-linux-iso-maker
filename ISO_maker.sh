#!/usr/bin/bash

# Configurable parameters

  KEYMAP="" # Only relevant if /etc/vconsole.conf doesn't exist
  ANSWERFILE_path="/home/fabse/answerfile" # e.g. /home/USERNAME/answerfile; must be named answerfile
  WIFI_ssid="WiFimodem-0CCC-5GHz" # e.g. HOMEBOX-24GHZ 
  WIFI_passwd="jtmkrmyyaz" # Won't be stored on the ISO; instead a passphrase will be generated using wpa_supplicant,
                 # which is unique to your wifi-ssid and wifi-password
                 # NOTICE: not filling these variables means that nmtui is executed at boot

#----------------------------------------------------------------------------------------------------------------------------------

# Assigning parameters

  if [[ "/etc/vconsole.conf" ]] && [[ -z "$KEYMAP" ]]; then
    KEYMAP="$(</etc/vconsole.conf)" # Defaults to local keymap
    KEYMAP_sorted=${KEYMAP#*=}
  fi
  if [[ -z "$ANSWERFILE_path" ]]; then
    SCRIPT="startup.sh"
  else
    SCRIPT="startup_with_answerfile.sh"
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Checking and installing any missing dependencies

  if [[ "$(pacman -Qs opendoas)" ]] && [[ -z "$(pacman -Qs sudo)" ]]; then
    doas pacman --noconfirm -S sudo
    echo "%wheel ALL=(ALL) ALL" | doas tee /etc/sudoers
    DELETE_1="true"
  fi
  if [[ -z "$(pacman -Qs openssl)" ]] && [[ "$ANSWERFILE_path" ]]; then
    sudo pacman --noconfirm -S openssl
    DELETE_2="true"
  fi
  if [[ -z "$(pacman -Qs artools)" ]]; then
    sudo pacman --noconfirm -S artools iso-profiles
    DELETE_3="true"
  fi
  if [[ -z "$(pacman -Qs wpa_supplicant)" ]] && [[ "$WIFI_ssid" && "$WIFI_passwd" ]]; then
    sudo pacman --noconfirm -S wpa_supplicant
    DELETE_4="true"
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Cleaning conflicting folders

  if [[ -d "/home/$(whoami)/ISO" ]]; then
    rm -rf /home/$(whoami)/ISO
  fi
  if [[ -d "/home/$(whoami)/BUILDISO" ]]; then
    if [[ -d "/home/$(whoami)/BUILDISO/buildiso/base/artix/bootfs" ]]; then
      sudo umount -l /home/$(whoami)/BUILDISO/buildiso/base/artix/bootfs
    fi
    if [[ -d "/home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs" ]]; then
      sudo umount -l /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs
    fi
    sudo rm -rf /home/$(whoami)/BUILDISO
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Copies configs and creates folders

  cp -rf artools /home/$(whoami)/.config
  cp -rf artools-workspace /home/$(whoami)
  mkdir /home/$(whoami)/{BUILDISO,ISO}
  sudo sed -i 's/\/usr\/src\/linux\/version/\/usr\/src\/linux-zen\/version/' /usr/bin/buildiso

#----------------------------------------------------------------------------------------------------------------------------------

# Builds the filesystem and applies modifications

  buildiso -p base -x
  sudo sed -i 's/--noclear/--autologin root --noclear/' /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/dinit.d/tty1
  sudo cp scripts/"$SCRIPT" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo mkdir /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/{script,.nothing,.encrypt,.decrypt}
  sudo cp scripts/keymap.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  sudo sed -i "3s/^/  KEYMAP=$KEYMAP_sorted\n/" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script/keymap.sh
  if [[ "$ANSWERFILE_path" ]]; then
    date | sha512sum > /home/$(whoami)/.nothing.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path" -out /home/$(whoami)/.encrypt.txt -pass file:/home/$(whoami)/.nothing.txt
    sudo cp /home/$(whoami)/{.nothing.txt,.encrypt.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  fi
  sudo touch /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf
  cat << EOF | sudo tee -a /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf > /dev/null
[device]
wifi.backend=iwd
EOF
  if [[ "$WIFI_ssid" && "$WIFI_passwd" ]]; then
    touch $WIFI_ssid.psk
    wpa_passphrase $WIFI_ssid $WIFI_passwd > network.txt
    WIFI_passphrase=$(sed '4q;d' network.txt)
    WIFI_passphrase_cut=${WIFI_passphrase:5}
    WIFI_passphrase_cut_clean=${WIFI_passphrase_cut//[[:blank:]]/}
   cat << EOF | tee -a $WIFI_ssid.psk > /dev/null    
[Security]
Passphrase=$WIFI_passphrase_cut_clean

EOF
    sudo mv $WIFI_ssid.psk /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/var/lib/iwd
    sudo chmod -R 777 /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/var/lib/iwd
    rm -rf network.txt
  fi
  sudo cp configs/pacman.conf /home/fabse/BUILDISO/buildiso/base/artix/rootfs/
  sudo cp scripts/repositories.sh /home/fabse/BUILDISO/buildiso/base/artix/rootfs/
  sudo chmod u+x /home/fabse/BUILDISO/buildiso/base/artix/rootfs/repositories.sh
  artix-chroot /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/ /bin/bash -c "bash /repositories.sh"
  sudo rm -rf /home/fabse/BUILDISO/buildiso/base/artix/rootfs/repositories.sh

#----------------------------------------------------------------------------------------------------------------------------------

# Continues building the ISO with auto-cleanup

  buildiso -p base -sc
  buildiso -p base -bc
  buildiso -p base -zc
  sudo rm -rf /home/$(whoami)/{BUILDISO,artools-workspace,.config/artools}
  if [[ "$DELETE_2" == "true" ]]; then
    sudo pacman --noconfirm -Rns openssl
  fi
  if [[ "$DELETE_3" == "true" ]]; then
    sudo pacman --noconfirm -Rns artools iso-profiles
  fi
  if [[ "$DELETE_3" == "true" ]]; then
    sudo pacman --noconfirm -Rns wpa_supplicant
  fi
  if [[ "$DELETE_1" == "true" ]]; then
    doas pacman --noconfirm -Rns sudo
  fi
  echo
  echo "----------------------------------------------------------------"
  echo "------YOUR CUSTOM ISO CAN BE FOUND AT /home/$(whoami)/ISO/base------"
  echo "----------------------------------------------------------------"
  echo 

