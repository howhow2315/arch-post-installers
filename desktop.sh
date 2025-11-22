#!/bin/bash
source ./base.sh

# IME
source ./ime.sh

# Realtime Audio
USERNAME=${SUDO_USER:-$USER}
if [[ -n "$USERNAME" ]]; then
    groupadd -f realtime
    
    mkdir -p /etc/security/limits.d
    [[ ! -f /etc/security/limits.d/99-realtime.conf ]] && cat <<EOF > /etc/security/limits.d/99-realtime.conf
@realtime   -   rtprio     95
@realtime   -   memlock    unlimited
EOF

    usermod -aG realtime "$USERNAME" # Realtime Permissions
    usermod -aG audio "$USERNAME" # MIDI Permissions
fi

# Fonts
_notif "Installing fonts"
pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji

# Plasma cleanup
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || _silently pgrep -x plasmashell; then
    _notif "KDE Plasma detected..." i

    # Flatpak + Flathub
    _notif_sep "Installing Flatpak + enabling Flathub..."
    pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Define apps
    pacman_apps=(
        firefox
        filelight
    )
    flatpak_apps=(
        com.github.tchx84.Flatseal
        it.mijorus.gearlever
        org.libreoffice.LibreOffice
    )

    # Install pacman apps
    _notif_sep "Installing pacman apps..."
    pacman -S --noconfirm "${pacman_apps[@]}"

    # Install flatpak apps
    _notif_sep "Installing flatpak apps..."
    flatpak install -y flathub "${flatpak_apps[@]}"
fi

# Done
_notif "Arch Linux post install setup complete!" o
timeleft=3
while [ $timeleft -gt 0 ]; do
    _notif "Rebooting in $timeleft..."; _bell; sleep 1
    ((timeleft--)) # decrement the counter
done
reboot