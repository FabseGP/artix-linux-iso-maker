#!/usr/bin/bash

  read -rp "Direct path to raw file, e.g. \"https://gitlab.com/FabseGP02/artix-linux-iso-maker/-/raw/main/answerfile\": " PATH
  wget -O /.nothing/answerfile_wget -q $PATH
