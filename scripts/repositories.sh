#!/usr/bin/bash

mv /pacman1.conf /etc/pacman.conf
pacman-key --init
pacman-key --refresh-keys
pacman -S --noconfirm artix-keyring artix-archlinux-support
pacman-key --init
pacman-key --populate archlinux artix
mv /pacman2.conf /etc/pacman.conf
