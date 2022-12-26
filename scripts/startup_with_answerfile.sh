#!/usr/bin/bash

  index=1
  cd /scripts || exit
  TYPE="$1"  
  for type in BASE MINIMAL FULL; do
    if [[ "$type" == "$TYPE" ]]; then
      openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -in encrypt$index.txt -out tmp.txt -pass file:nothing$index.txt
      date | sha512sum > /.nothing/nothing.txt
      openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in tmp.txt -out /.encrypt/answer_encrypt.txt -pass file:/.nothing/nothing.txt
      (( index++ )) || true
    else (( index++ )) || true; fi
  done
  ./keymap.sh
  cd || exit
  until ping -c 1 xkcd.com &> /dev/null; do nmtui; done
  pacman-key --init 
  pacman-key --populate artix archlinux 
  pacman -Scc --noconfirm 
  pacman -Syy  
  git clone https://gitlab.com/FabseGP02/artix-install-script.git 
  cd artix-install-script || exit 
  ./install_artix.sh
