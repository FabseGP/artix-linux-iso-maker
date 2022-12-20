#!/usr/bin/bash

# Static parameters

  BEGINNER_DIR=$(pwd)
  index=1
  today=$(date +"%Y_%m_%d-%T")
  shopt -s nullglob
  ISO_path=$(echo /home/$(whoami)/ISO/base/*.iso)

#----------------------------------------------------------------------------------------------------------------------------------

# Configurable parameters

  KEYMAP="" # Only relevant if /etc/vconsole.conf doesn't exist
  ANSWERFILE_path_base="" # e.g. /home/USERNAME/answerfile_base; must be named answerfile_base
  ANSWERFILE_path_minimal="" # e.g. /home/USERNAME/answerfile_minimal; must be named answerfile_minimal
  ANSWERFILE_path_full="" # e.g. /home/USERNAME/answerfile_full; must be named answerfile_full

#----------------------------------------------------------------------------------------------------------------------------------

# Updating pacman-config + backup of existing

  if [[ "$(pacman -Qs opendoas)" ]] && ! [[ "$(pacman -Qs --color always "sudo" | grep "local" | grep "sudo ")" == "" ]]; then COMMAND="doas"; 
  else SU_COMMAND="sudo"; fi
  if [[ -z "$(pacman -Qs artix-archlinux-support)" ]]; then "$SU_COMMAND" pacman -Syy --noconfirm --needed artix-archlinux-support; "$SU_COMMAND" pacman-key --populate archlinux; fi

#----------------------------------------------------------------------------------------------------------------------------------

# Assigning parameters

  if [[ "/etc/vconsole.conf" ]] && [[ -z "$KEYMAP" ]]; then KEYMAP="$(</etc/vconsole.conf)"; KEYMAP_sorted=${KEYMAP#*=}; fi

#----------------------------------------------------------------------------------------------------------------------------------

# Checking and installing any missing dependencies

  if [[ "$(pacman -Qs opendoas)" ]] && [[ -z "${check_sudo}" ]]; then
    if [[ -f "/usr/bin/sudo" ]]; then doas rm -rf /usr/bin/sudo; RESTORE_sudo="true"; fi
    doas pacman --noconfirm --needed -S sudo && echo ""$USER" ALL=(ALL:ALL) NOPASSWD: ALL" | doas tee -a /etc/sudoers > /dev/null && DELETE_sudo="true"
  fi
  if [[ -z "$(pacman -Qs openssl)" ]] && [[ "$ANSWERFILE_path_minimal" || "$ANSWERFILE_path_full" ]]; then sudo pacman --noconfirm --needed -S openssl; DELETE_openssl="true"; fi
  if [[ -z "$(pacman -Qs artools)" ]]; then sudo pacman --noconfirm --needed -S artools iso-profiles; fi

#----------------------------------------------------------------------------------------------------------------------------------

# Cleaning conflicting folders

  if [[ "$ISO_path" ]]; then mv -f /home/$(whoami)/ISO/base /home/$(whoami)/ISO/base-"$today"; fi
  if [[ -d "/home/$(whoami)/BUILDISO" ]]; then
    if [[ -d "/home/$(whoami)/BUILDISO/buildiso/base/artix/bootfs" ]]; then sudo umount -l /home/$(whoami)/BUILDISO/buildiso/base/artix/bootfs; fi
    if [[ -d "/home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs" ]]; then sudo umount -l /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs; fi
    sudo rm -rf /${home/$(whoami)/BUILDISO:?}
  fi

#----------------------------------------------------------------------------------------------------------------------------------

# Copies configs and creates folders

  cp -rf artools /home/$(whoami)/.config && cp -rf artools-workspace /home/$(whoami) && mkdir /home/$(whoami)/{BUILDISO,ISO}
  sudo sed -i 's/\/usr\/src\/linux\/version/\/usr\/src\/linux-zen\/version/' /usr/bin/buildiso

#----------------------------------------------------------------------------------------------------------------------------------

# Builds the filesystem and applies modifications

  sudo modprobe loop && buildiso -p base -x
  sudo sed -i 's/--noclear/--autologin root --noclear/' /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/dinit.d/tty1
  sudo cp scripts/startup_choice.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/profile.d/startup_choice.sh
  sudo mkdir /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/{scripts,.nothing,.encrypt,.decrypt}
  sudo cp scripts/{startup.sh,startup_with_answerfile.sh,startup_wget_answerfile.sh,keymap.sh} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
  sudo sed -i "3s/^/  KEYMAP=$KEYMAP_sorted\n/" /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts/keymap.sh
  for answerfile in $ANSWERFILE_path_base $ANSWERFILE_path_minimal $ANSWERFILE_path_full; do
    if [[ "$answerfile" ]]; then
      mkdir /home/$(whoami)/.nothing$index
      date | sha512sum > /home/$(whoami)/.nothing$index/nothing$index.txt
      openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in "$ANSWERFILE_path_base" -out /home/$(whoami)/.nothing$index/encrypt$index.txt -pass file:/home/$(whoami)/.nothing$index/nothing$index.txt
      sudo cp /home/$(whoami)/.nothing$index/{nothing$index.txt,encrypt$index.txt} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/scripts
      rm -rf /${home/$(whoami)/.nothing$index:?}
      (( index++ )) || true
    else (( index++ )) || true; fi
  done
  sudo cp configs/wifi_backend.conf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/etc/NetworkManager/conf.d/wifi_backend.conf
  sudo cp configs/{pacman_with_arch.conf,pacman_without_arch.conf} /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  sudo cp scripts/repositories.sh /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/
  artix-chroot /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/ /bin/bash -c "bash /repositories.sh"
  sudo rm -rf /home/$(whoami)/BUILDISO/buildiso/base/artix/rootfs/repositories.sh

#----------------------------------------------------------------------------------------------------------------------------------

# Continues building the ISO with auto-cleanup

  buildiso -p base -sc && buildiso -p base -bc && buildiso -p base -zc
  sudo rm -rf /home/$(whoami)/BUILDISO
  if [[ "$DELETE_openssl" == "true" ]]; then sudo pacman --noconfirm -Rns openssl; fi
  if [[ "$DELETE_sudo" == "true" ]]; then doas pacman --noconfirm -Rns sudo; fi
  if [[ "$RESTORE_sudo" == "true" ]]; then doas ln -s $(which doas) /usr/bin/sudo; fi
  echo
  echo "----------------------------------------------------------------"
  echo "------YOUR CUSTOM ISO CAN BE FOUND AT /home/$(whoami)/ISO/base------"
  echo "----------------------------------------------------------------"
  echo 
