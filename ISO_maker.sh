#/usr/bin/bash

# Configurable parameters

  KEYMAP="" # Only relevant if /etc/vconsole.conf doesn't exist
  ANSWERFILE_path="" # e.g. /home/USERNAME/answerfile

#----------------------------------------------------------------------------------------------------------------------------------

# Assigning parameters

  if [[ "/etc/vconsole.conf" ]] && [[ -z "$KEYMAP" ]]; then
    KEYMAP_fetch="$(</etc/vconsole.conf)" # Defaults to local keymap
    KEYMAP=${KEYMAP#*=}
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
    DELETE="true"
  fi
  if [[ -z "$(pacman -Qs artools)" ]]; then
    sudo pacman --noconfirm -S artools iso-profiles
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

#----------------------------------------------------------------------------------------------------------------------------------

# Builds the filesystem and applies modifications

  buildiso -p base -x
  sudo sed -i 's/--noclear/--autologin root --noclear/' /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/dinit.d/tty1
  sudo cp scripts/"$SCRIPT" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo chmod u+x /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup.sh
  sudo mkdir /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  sudo cp scripts/keymap.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  if [[ "$ANSWERFILE_path" ]]; then
    sudo sed -i "3s/^/  KEYMAP=$KEYMAP\n/" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script/keymap.sh
  fi
  if [[ "$ANSWERFILE_path" ]]; then
    sudo cp "$ANSWERFILE_path" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/script
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Continues building the ISO with deletion of build-folder

  buildiso -p base -sc
  buildiso -p base -bc
  buildiso -p base -zc
  sudo rm -rf /home/$(whoami)/BUILDISO
  if [[ "$DELETE" == "true" ]]; then
    doas pacman --noconfirm -Rns sudo
  fi