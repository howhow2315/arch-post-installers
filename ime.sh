#!/bin/bash
[[ ! $COMMON_INITIALIZED ]] && source ./common.sh

# IME
_notif_sep "IME..."
_notif "Installing fcitx5..."
pacman -S --noconfirm fcitx5-im fcitx5-configtool fcitx5-gtk fcitx5-qt

cat <<EOF >> /etc/environment

# Virtual Keyboard / IME / fcitx 5
INPUT_METHOD=fcitx
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=fcitx

EOF
_notif "Fcitx 5 IME environment variables set."