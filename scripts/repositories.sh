#!/usr/bin/bash

pacman-key --init
pacman -Syyu
pacman-key --populate
pacman-key --refresh-keys
pacman -Sy --noconfirm artix-keyring artix-archlinux-support
pacman-key --init
pacman-key --populate archlinux artix
mv /pacman.conf /etc/pacman.conf
pacman -Syy
