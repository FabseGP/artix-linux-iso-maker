#!/usr/bin/bash

# Static parameters

  BEGINNER_DIR=$(pwd)

#----------------------------------------------------------------------------------------------------------------------------------

# Configurable parameters

  KEYMAP="" # Only relevant if /etc/vconsole.conf doesn't exist
  ANSWERFILE_path_base="" # e.g. /home/USERNAME/answerfile_base; must be named answerfile_base
  ANSWERFILE_path_minimal="" # e.g. /home/USERNAME/answerfile_minimal; must be named answerfile_minimal
  ANSWERFILE_path_full="" # e.g. /home/USERNAME/answerfile_full; must be named answerfile_full

#----------------------------------------------------------------------------------------------------------------------------------

# Updating pacman-config + backup of existing

  check_sudo="$(pacman -Qs --color always "sudo" | grep "local" | grep "sudo ")"
  if [[ "$(pacman -Qs opendoas)" ]] && [[ -z "${check_sudo}" ]]; then
    su_command="doas"
  else
    su_command="sudo"
  fi
  if [[ -z "$(pacman -Qs artix-archlinux-support)" ]]; then
    "$su_command" pacman -Syy --noconfirm artix-archlinux-support
    "$su_command" pacman-key --populate archlinux
  fi
  if [[ -z "$(pacman -Qs chaotic-keyring)" ]]; then
    "$su_command" pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    "$su_command" pacman-key --lsign-key FBA220DFC880C036
    "$su_command" pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Assigning parameters

  if [[ "/etc/vconsole.conf" ]] && [[ -z "$KEYMAP" ]]; then
    KEYMAP="$(</etc/vconsole.conf)" # Defaults to local keymap
    KEYMAP_sorted=${KEYMAP#*=}
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Checking and installing any missing dependencies

  if [[ "$(pacman -Qs opendoas)" ]] && [[ -z "${check_sudo}" ]]; then
    if [[ -f "/usr/bin/sudo" ]]; then
      doas rm -rf /usr/bin/sudo
      RESTORE_1="true"
    fi
    doas pacman --noconfirm -S sudo
    echo ""$USER" ALL=(ALL:ALL) NOPASSWD: ALL" | doas tee -a /etc/sudoers > /dev/null
    DELETE_1="true"
  fi
  if [[ -z "$(pacman -Qs openssl)" ]] && [[ "$ANSWERFILE_path_minimal" || "$ANSWERFILE_path_full" ]]; then
    sudo pacman --noconfirm -S openssl
    DELETE_2="true"
  fi
  if [[ -z "$(pacman -Qs artools)" ]]; then
    sudo pacman --noconfirm -S artools iso-profiles
    DELETE_3="true"
  fi
  if [[ "$(pacman -Qs snap-pac)" ]]; then
    sudo mv /etc/pacman.d/hooks/{*-snap-*,*_snap-*} /etc
    sudo mv /usr/share/libalpm/hooks/{*-snap-*,*_snap-*} /usr
    RESTORE_2="true"
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

  sudo modprobe loop
  buildiso -p base -x
  sudo sed -i 's/--noclear/--autologin root --noclear/' /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/dinit.d/tty1
  sudo cp scripts/startup_choice.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup_choice.sh
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup_choice.sh
  sudo mkdir /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/{scripts,.nothing,.encrypt,.decrypt}
  sudo cp scripts/{startup.sh,startup_with_answerfile.sh,startup_wget_answerfile.sh,keymap.sh} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts/*
  sudo sed -i "3s/^/  KEYMAP=$KEYMAP_sorted\n/" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts/keymap.sh
  if [[ "$ANSWERFILE_path_base" ]]; then
    mkdir /home/$(whoami)/.nothing1
    date | sha512sum > /home/$(whoami)/.nothing1/nothing1.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path_base" -out /home/$(whoami)/.nothing1/encrypt1.txt -pass file:/home/$(whoami)/.nothing1/nothing1.txt
    sudo cp /home/$(whoami)/.nothing1/{nothing1.txt,encrypt1.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
    rm -rf /home/$(whoami)/.nothing1
  fi
  if [[ "$ANSWERFILE_path_minimal" ]]; then
    mkdir /home/$(whoami)/.nothing2
    date | sha512sum > /home/$(whoami)/.nothing2/nothing2.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path_minimal" -out /home/$(whoami)/.nothing2/encrypt2.txt -pass file:/home/$(whoami)/.nothing2/nothing2.txt
    sudo cp /home/$(whoami)/.nothing2/{nothing2.txt,encrypt2.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
    rm -rf /home/$(whoami)/.nothing2
  fi
  if [[ "$ANSWERFILE_path_full" ]]; then
    mkdir /home/$(whoami)/.nothing3
    date | sha512sum > /home/$(whoami)/.nothing3/nothing3.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path_full" -out /home/$(whoami)/.nothing3/encrypt3.txt -pass file:/home/$(whoami)/.nothing3/nothing3.txt
    sudo cp /home/$(whoami)/.nothing3/{nothing3.txt,encrypt3.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
    rm -rf /home/$(whoami)/.nothing3
  fi
  sudo touch /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf
  cat << EOF | sudo tee -a /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf > /dev/null
[device]
wifi.backend=iwd
EOF
  sudo cp configs/{pacman1.conf,pacman2.conf} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  sudo cp scripts/repositories.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/repositories.sh
  artix-chroot /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/ /bin/bash -c "bash /repositories.sh"
  sudo rm -rf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/repositories.sh
  if [[ "$(pacman -Qs rtl8812au-dkms-git)" ]]; then
    sudo cp packages/rtl8812au-dkms-git-5.13.6.r128.g7aa0e0c-1-x86_64.pkg.tar.zst /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs
    artix-chroot /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs /bin/bash -c "pacman --noconfirm -U rtl8812au-dkms-git-5.13.6.r128.g7aa0e0c-1-x86_64.pkg.tar.zst"
    sudo rm -rf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/rtl8812au-dkms-git-5.13.6.r128.g7aa0e0c-1-x86_64.pkg.tar.zst
  fi

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
  if [[ "$RESTORE_2" == "true" ]]; then
    sudo mv /etc/{*-snap-*,*_snap-*} /etc/pacman.d/hooks/
    sudo mv /usr/{*-snap-*,*_snap-*} /usr/share/libalpm/hooks
  fi
  if [[ "$DELETE_1" == "true" ]]; then
    doas pacman --noconfirm -Rns sudo
  fi
  if [[ "$RESTORE_1" == "true" ]]; then
    doas ln -s $(which doas) /usr/bin/sudo
  fi
  echo
  echo "----------------------------------------------------------------"
  echo "------YOUR CUSTOM ISO CAN BE FOUND AT /home/$(whoami)/ISO/base------"
  echo "----------------------------------------------------------------"
  echo 
