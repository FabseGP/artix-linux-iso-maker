#!/usr/bin/bash

  TYPE="$1"  

  if [[ "$TYPE" == "BASE" ]]; then
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -in encrypt1.txt -out tmp.txt -pass file:nothing1.txt
    date | sha512sum > /.nothing/nothing.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in tmp.txt -out /.encrypt/answer_encrypt.txt -pass file:/.nothing/nothing.txt
    rm -rf {encrypt1.txt,tmp.txt,nothing1.txt}
  elif [[ "$TYPE" == "MINIMAL" ]]; then
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -in encrypt2.txt -out tmp.txt -pass file:nothing2.txt
    date | sha512sum > /.nothing/nothing.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in tmp.txt -out /.encrypt/answer_encrypt.txt -pass file:/.nothing/nothing.txt
    rm -rf {encrypt2.txt,tmp.txt,nothing2.txt}  
  elif [[ "$TYPE" == "FULL" ]]; then
    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -in encrypt3.txt -out tmp.txt -pass file:nothing3.txt
    date | sha512sum > /.nothing/nothing.txt
    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -in tmp.txt -out /.encrypt/answer_encrypt.txt -pass file:/.nothing/nothing.txt
    rm -rf {encrypt3.txt,tmp.txt,nothing3.txt}
  fi
  chmod u+x keymap.sh
  ./keymap.sh
  cd || exit
  until ping -c 1 xkcd.com &> /dev/null; do
    nmtui
  done
  pacman-key --init
  pacman-key --populate artix archlinux
  pacman -Scc --noconfirm
  pacman -Syy  
  git clone https://gitlab.com/FabseGP02/artix-install-script.git
  cd artix-install-script || exit
  chmod u+x install_artix.sh
  ./install_artix.sh
