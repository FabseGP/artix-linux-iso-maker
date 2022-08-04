#!/usr/bin/bash

# Configurable parameters

  KEYMAP="" # Only relevant if /etc/vconsole.conf doesn't exist
  ANSWERFILE_path="" # e.g. /home/USERNAME/answerfile; must be named answerfile

#----------------------------------------------------------------------------------------------------------------------------------

# Updating pacman-config + backup of existing

  sudo cp /etc/pacman.conf /etc/pacman-backup.conf
  if [[ -z "$(pacman -Qs artix-archlinux-support)" ]]; then
    sudo cp -rf configs/pacman1.conf /etc/pacman.conf
    sudo pacman -Syy
    sudo pacman -S --noconfirm artix-archlinux-support
    sudo pacman-key --populate archlinux
  fi
  sudo cp -rf configs/pacman2.conf /etc/pacman.conf
  sudo pacman -Syy

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
  check_sudo="$(pacman -Qs --color always "sudo" | grep "local" | grep "sudo ")"

#----------------------------------------------------------------------------------------------------------------------------------

# Checking and installing any missing dependencies

  if [[ "$(pacman -Qs opendoas)" ]] && [[ -z "${check_sudo}" ]]; then
    if [[ -f "/usr/bin/sudo" ]]; then
      doas rm -rf /usr/bin/sudo
      RESTORE_1="true"
    fi
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
  sudo cp scripts/"$SCRIPT" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo mkdir /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/{script,.nothing,.encrypt,.decrypt}
  sudo cp scripts/keymap.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  sudo sed -i "3s/^/  KEYMAP=$KEYMAP_sorted\n/" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script/keymap.sh
  if [[ "$ANSWERFILE_path" ]]; then
    mkdir /home/$(whoami)/.nothing
    date | sha512sum > /home/$(whoami)/.nothing/nothing.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path" -out /home/$(whoami)/.nothing/encrypt.txt -pass file:/home/$(whoami)/.nothing/nothing.txt
    sudo cp /home/$(whoami)/.nothing/{nothing.txt,encrypt.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
    rm -rf /home/$(whoami)/.nothing
  fi
  sudo touch /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf
  cat << EOF | sudo tee -a /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf > /dev/null
[device]
wifi.backend=iwd
EOF
  sudo cp configs/pacman.conf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  sudo cp scripts/repositories.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/repositories.sh
  artix-chroot /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/ /bin/bash -c "bash /repositories.sh"
  sudo rm -rf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/repositories.sh

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
  if [[ "$DELETE_1" == "true" ]]; then
    doas pacman --noconfirm -Rns sudo
  fi
  if [[ "$RESTORE_1" == "true" ]]; then
    doas ln -s $(which doas) /usr/bin/sudo
  fi
  sudo mv /etc/pacman-backup.conf /etc/pacman.conf
  sudo pacman -Syy
  echo
  echo "----------------------------------------------------------------"
  echo "------YOUR CUSTOM ISO CAN BE FOUND AT /home/$(whoami)/ISO/base------"
  echo "----------------------------------------------------------------"
  echo 

