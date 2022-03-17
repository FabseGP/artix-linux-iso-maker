#!/usr/bin/bash

  cd /script || exit
  chmod u+x keymap.sh
  ./keymap.sh
  cd || exit
  until ping -c 1 xkcd.com &> /dev/null; do
    nmtui
  done
  pacman -Sy
  git clone https://gitlab.com/FabseGP02/artix-install-script.git
  cd artix-install-script || exit
  chmod u+x install_artix.sh
  ./install_artix.sh
