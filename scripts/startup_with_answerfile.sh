#/usr/bin/bash

  cd /script
  ./keymap.sh
  cd
  until ping -c 1 xkcd.com &> /dev/null; do
    nmtui
  done
  pacman -Sy
  git clone https://gitlab.com/FabseGP02/artix-install-script.git
  cd artix-install-script
  chmod u+x install_artix.sh
  cp /script/answerfile .
  ./install_artix.sh
