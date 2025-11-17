#!/bin/bash
[[ ! $COMMON_INITIALIZED ]] && source ./common.sh
_require_root "$@"

# Add host to hosts
HOSTNAME=$(cat /etc/hostname)
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.1.1    $HOSTNAME.localdomain    $HOSTNAME" || _silently sudo tee -a /etc/hosts

# Add custom pacman repo [howhow]
_silently grep -i "howhow" /etc/pacman.conf || _silently sudo tee -a /etc/pacman.conf <<'EOF'

[howhow]
SigLevel = Optional TrustAll
Server = https://howhow2315.github.io/linux-packages
EOF

# Mirrors and system upgrade
_notif_sep "Updating mirrors and upgrading system..."
_notif "Fetching latest Arch mirrors and syncing package databases..."

reflector --score 25 --latest 25 --threads 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu

# AUR package manager
pacman -S --noconfirm aurinstall
aurinstall paru-bin
pacman -R --noconfirm aurinstall

# Battery
if _silently ls /sys/class/power_supply/BAT*; then
    _notif_sep "Battery detected installing power saving..."
    pacman -S --noconfirm tlp
    systemctl enable tlp
fi

# SSD
_notif_sep "SSD..."
if [[ $(_get_rotational_flag) -eq 0 ]]; then
    _notif "SSD detected: enabling fstrim.timer"
    systemctl enable --now fstrim.timer
fi

# Terminal tools
_notif_sep "Installing terminal tools (bash-completion, pacman-contrib, fastfetch, tmux)..."
pacman -S --noconfirm bash-completion pacman-contrib fastfetch tmux
grep -qxF "fastfetch" /etc/bash.bashrc || echo "fastfetch" >> /etc/bash.bashrc

# Sensors
_notif_sep "Installing sensors (lm_sensors acpi acpid)..." 
pacman -S --noconfirm lm_sensors acpi acpid 
systemctl enable acpid
_notif "Detecting sensors..."
sensors-detect --auto

# Networking
_notif_sep "Networking..."
_notif "Installing network monitor (vnstat)..."
pacman -S --noconfirm vnstat
systemctl enable vnstat

_notif "Installing networking tools (wget)..."
pacman -S --noconfirm wget

# Use Encrypted DNS
_notif_sep "Enabling EDNS..."
cat <<EOF > "/etc/systemd/resolved.conf" # Configure DNS-over-TLS
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=8.8.8.8#dns.google
DNSOverTLS=yes
Cache=yes
EOF
systemctl enable --now systemd-resolved

# Firewall
_notif_sep "Installing Firewall (ufw)..."
pacman -S --noconfirm ufw
ufw enable
systemctl enable ufw

# SSH
_notif_sep "SSH..."
_notif "Installing OpenSSH and fail2ban..."
pacman -S --noconfirm openssh fail2ban
cp -n /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i '/^\[sshd\]$/a enabled = true' /etc/fail2ban/jail.local
systemctl enable --now fail2ban

_notif "Please disable password auth in /etc/ssh/sshd_config.d/sshd_harden.conf" !
tee /etc/ssh/sshd_config.d/sshd_harden.conf >/dev/null <<'EOF'
# Hardened SSH configuration

# Custom SSH port
Port 2222

# Don't allow remote root login
PermitRootLogin no

# Only allow public key authentication
# PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no

# Disable obsolete authentication
UsePAM yes

# Modern, secure protocol + algorithms
Protocol 2
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no

# Prevent empty passwords
PermitEmptyPasswords no

# Reduce login grace time
LoginGraceTime 30

# Limit auth attempts
MaxAuthTries 3

# Disable banners to avoid fingerprinting
DebianBanner no
EOF

ufw allow from 192.168.0.0/16 to any port 2222 proto tcp comment "SSH LAN" # Allow SSH on port 2222 only from LAN
ufw reload