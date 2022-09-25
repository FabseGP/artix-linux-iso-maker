#!/usr/bin/bash

  cd /scripts || exit
  ./keymap.sh
  cd || exit
  until ping -c 1 xkcd.com &> /dev/null; do
    nmtui
  done
  pacman-key --init
  pacman-key --populate artix archlinux
  pacman -Scc --noconfirm
  pacman -Sy    
  git clone https://gitlab.com/FabseGP02/artix-install-script.git
  cd artix-install-script || exit
  ./install_artix.sh
