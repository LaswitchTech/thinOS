#!/bin/bash

# Don't run as root – use: ./setup.sh (with sudo inside)
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a normal user, not as root."
    echo "It uses sudo internally where needed."
    exit 1
fi

# Function to detect the operating system distribution
get_distribution() {
    if [ "$(cat /proc/cpuinfo | egrep -i "raspberry pi")" != "" ]; then
        echo "raspbian"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Get the distribution
DISTRO=$(get_distribution)

# Function to print the current step
log_step() {
    echo "Step $1: $2"
}

# Update the system
log_step 1 "Updating the Operating System..."
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt-get full-upgrade -y
else
    echo "Unsupported distribution: $DISTRO"
    exit 1
fi

# Install necessary packages based on the distribution
log_step 2 "Installing a Minimal Desktop Environment, Git, Firefox, ImageMagick, and feh..."
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y git || true
    sudo apt-get install -y net-tools || true
    sudo apt-get install -y nmap || true
    sudo apt-get install -y fping || true
    sudo apt-get install -y dnsutils || true
    sudo apt-get install -y lightdm || true
    sudo apt-get install -y openbox || true
    sudo apt-get install -y udevil || true
    sudo apt-get install -y libnotify-bin || true
    sudo apt-get install -y exfatprogs || true
    sudo apt-get install -y ntfs-3g || true
    sudo apt-get install -y exfat-fuse || true
    sudo apt-get install -y exfatprogs || true
    sudo apt-get install -y firefox-esr || true
    sudo apt-get install -y alsa-utils || true
    sudo apt-get install -y pulseaudio pavucontrol || true
    sudo apt-get install -y v4l-utils || true
    sudo apt-get install -y xterm || true
    sudo apt-get install -y plymouth || true
    sudo apt-get install -y plymouth-themes || true
    sudo apt-get install -y imagemagick feh || true
    # sudo apt-get install -y freerdp2-x11 || true
    # sudo apt-get install -y freerdp3-x11 || true
    sudo apt-get install -y libswscale6 || true
    sudo apt-get install -y liburiparser1 || true
    sudo apt-get install -y libcjson1 || true
    sudo apt-get install -y openvpn || true
    sudo apt-get install -y wireguard-tools || true
    sudo apt-get install -y python3 || true
    sudo apt-get install -y python3-pyqt5 || true
    sudo apt-get install -y python3-pyqt5* || true
else
    echo "Unsupported distribution: $DISTRO"
    exit 1
fi

# Ensure the current user is in the correct groups for audio and video devices
log_step "2a" "Ensuring user has access to audio and video devices..."
sudo usermod -aG audio,video "$USER" || true

# Install or update the thinOS repository in /usr/share
log_step 3 "Installing or updating thinOS in /usr/share..."
if [ -d "/usr/share/thinOS/.git" ]; then
    sudo git -C /usr/share/thinOS pull
else
    sudo git clone --recursive --branch dev https://github.com/LaswitchTech/thinOS.git /usr/share/thinOS
fi

# Configure uDevil to allow non-sudo mounting of USB drives
log_step "3a" "Configuring uDevil for non-sudo USB mounting..."

# Ensure dirs exist
sudo mkdir -p /etc/udevil
sudo mkdir -p /usr/local/bin

# Symlink configs & helper
sudo ln -sfn /usr/share/thinOS/src/etc/udevil/udevil.conf /etc/udevil/udevil.conf
sudo ln -sfn /usr/share/thinOS/src/usr/local/bin/thinos-devmon /usr/local/bin/thinos-devmon
sudo chmod +x /usr/local/bin/thinos-devmon || true

# Add user to plugdev group
sudo usermod -aG plugdev "$USER" || true

# Install or update the PyRDPConnect repository in /usr/share
log_step 4 "Installing or updating the PyRDPConnect repository in /usr/share..."
if [ -d "/usr/share/PyRDPConnect/.git" ]; then
    sudo git -C /usr/share/PyRDPConnect pull
else
    sudo git clone --recursive --branch dev https://github.com/LaswitchTech/PyRDPConnect.git /usr/share/PyRDPConnect
fi

# Create a gradient background image
log_step 5 "Creating a gradient background image..."
mkdir -p ~/.config/thinOS/backgrounds
convert -size 1920x1080 gradient:'#76797c-#242829' ~/.config/thinOS/backgrounds/gradient.png

# Configure Openbox
log_step 6 "Configuring Openbox..."
sudo sed -i 's/^#user-session=.*/user-session=openbox/' /etc/lightdm/lightdm.conf
mkdir -p ~/.config
ln -sfn /usr/share/thinOS/src/openbox ~/.config/openbox
ln -sfn /usr/share/thinOS/src/.xinitrc ~/.xinitrc
ln -sfn /usr/share/thinOS/src/.xinitrc ~/.xsession
mkdir -p ~/.themes
ln -sfn /usr/share/thinOS/src/thinOS ~/.themes/thinOS
ln -sfn /usr/share/thinOS/src/.Xdefaults ~/.Xdefaults

# Setup bash profile and aliases
log_step 7 "Setup bash profile and aliases..."
ln -sfn /usr/share/thinOS/src/.bash_profile ~/.bash_profile
ln -sfn /usr/share/thinOS/src/.bash_aliases ~/.bash_aliases

# Set locale and timezone
log_step 8 "Setting locale and timezone..."
sudo sed -i '/en_GB.UTF-8/s/^/#/' /etc/locale.gen
sudo sed -i '/en_CA.UTF-8/s/^# //g' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_CA.UTF-8
sudo timedatectl set-timezone America/Toronto

# Configure PolicyKit for non-sudo reboot and shutdown
log_step 9 "Configuring PolicyKit for non-sudo reboot/shutdown..."
sudo bash -c 'cat <<EOL > /etc/polkit-1/localauthority/50-local.d/10-power-management.pkla
[Allow Reboot and Shutdown]
Identity=unix-user:*
Action=org.freedesktop.login1.reboot;org.freedesktop.login1.power-off
ResultActive=yes
EOL'

# Disable verbose boot and enable Plymouth theme
log_step 10 "Disabling verbose boot and enabling Plymouth theme..."
FILE=/boot/firmware/cmdline.txt
if [ -f "$FILE" ]; then
    if ! grep -q "splash" "$FILE"; then
        sudo sed -i 's/$/ splash quiet plymouth.ignore-serial-consoles/' "$FILE"
    fi
fi

# Copy and set custom Plymouth theme
log_step 11 "Setting the custom Plymouth theme..."
sudo rm -rf /usr/share/plymouth/themes/thinOS
sudo cp -rf /usr/share/thinOS/src/plymouth /usr/share/plymouth/themes/thinOS
sudo plymouth-set-default-theme -R thinOS
sudo update-initramfs -u

# Configure system and Firefox dark mode using repo-based configs
log_step 12 "Configuring system and Firefox dark mode..."

# System GTK dark mode (source of truth in /usr/share/thinOS/src)
if [ -f /usr/share/thinOS/src/gtk/settings.ini ]; then
    mkdir -p ~/.config/gtk-3.0
    ln -sfn /usr/share/thinOS/src/gtk/settings.ini ~/.config/gtk-3.0/settings.ini
fi

# Firefox dark mode via user.js (source of truth in /usr/share/thinOS/src)
if [ -f /usr/share/thinOS/src/firefox/user.js ]; then
    if [ -d ~/.mozilla/firefox ]; then
        for FF_PROFILE in ~/.mozilla/firefox/*.default ~/.mozilla/firefox/*.default-esr; do
            [ -d "$FF_PROFILE" ] || continue
            ln -sfn /usr/share/thinOS/src/firefox/user.js "$FF_PROFILE/user.js"
        done
    fi
fi

# Enable auto-login for Debian
if [ "$DISTRO" == "debian" ]; then
    log_step 13 "Enabling auto-login for Debian..."
    if grep -q "^#autologin-user=" /etc/lightdm/lightdm.conf; then
        sudo sed -i "s/^#autologin-user=.*/autologin-user=$USER/" /etc/lightdm/lightdm.conf
    else
        echo "autologin-user=$USER" | sudo tee -a /etc/lightdm/lightdm.conf
    fi

    if grep -q "^#autologin-user-timeout=" /etc/lightdm/lightdm.conf; then
        sudo sed -i "s/^#autologin-user-timeout=.*/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf
    else
        echo "autologin-user-timeout=0" | sudo tee -a /etc/lightdm/lightdm.conf
    fi
fi

#
# Additional Raspberry Pi OS-specific configurations
if [ "$DISTRO" == "raspbian" ]; then
    log_step 14 "Configuring Raspberry Pi OS for desktop boot and multi-monitor support..."

    # Boot to desktop
    sudo raspi-config nonint do_boot_behaviour B4

    # Choose correct config path (Bookworm vs older)
    CFG=/boot/firmware/config.txt
    [ -f "$CFG" ] || CFG=/boot/config.txt

    if printf '%s\n' "$@" | grep -q -- --multimon; then
        # Only add our block once, marked by a comment
        if ! grep -q "thinOS-multimon" "$CFG"; then
            sudo bash -c "cat <<'EOL' >> '$CFG'

# thinOS-multimon
# Enable HDMI output for both monitors
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1

# Set HDMI group and mode (1080p)
hdmi_group:0=2
hdmi_mode:0=82
hdmi_group:1=2
hdmi_mode:1=82

# Disable overscan compensation
disable_overscan=1

# Disable firmware splash on Pi
disable_splash=1
EOL"
        fi
    fi
fi

# Cleanup step
log_step 15 "cleanup..."
# Remove setup script
if [ -f "$HOME/setup.sh" ]; then
    rm "$HOME/setup.sh"
fi
# Remove bash_history
if [ -f "$HOME/.bash_history" ]; then
    rm "$HOME/.bash_history"
fi
# Auto remove unused packages
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    sudo apt-get autoremove -y
fi

# Final instructions
log_step 16 "Setup completed. Please reboot the system to apply the changes."
