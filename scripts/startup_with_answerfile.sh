#!/usr/bin/bash

  cd /script || exit
  chmod u+x keymap.sh
  openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -in encrypt.txt -out tmp.txt -pass file:nothing.txt
  date | sha512sum > /.nothing/nothing.txt
  openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in tmp.txt -out /.encrypt/answer_encrypt.txt -pass file:/.nothing/nothing.txt
  rm -rf {encrypt.txt,tmp.txt,nothing.txt}
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
