#!/usr/bin/bash

  mv /pacman_without_arch.conf /etc/pacman.conf
  pacman-key --init 
  pacman-key --populate 
  pacman-key --refresh-keys
  pacman -Sy --noconfirm artix-keyring artix-archlinux-support
  pacman-key --init
  pacman-key --populate archlinux artix
  mv /pacman_with_arch.conf /etc/pacman.conf
