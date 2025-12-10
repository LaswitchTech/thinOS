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

# Default Branch
BRANCH="stable"

# Parse arguments for --branch
while [ "$#" -gt 0 ]; do
    case "$1" in
        --branch)
            if [ -n "$2" ]; then
                BRANCH="$2"
                shift 2
                continue
            else
                echo "Error: --branch requires a value (e.g. --branch dev)" >&2
                exit 1
            fi
            ;;
        --branch=*)
            BRANCH="${1#*=}"
            shift
            continue
            ;;
        *)
            shift
            ;;
    esac
done

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
    sudo apt-get install -y info || true
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
    sudo apt-get install -y libswscale6 || true
    sudo apt-get install -y liburiparser1 || true
    sudo apt-get install -y libcjson1 || true
    sudo apt-get install -y libcap2-bin || true
    sudo apt-get install -y openvpn || true
    sudo apt-get install -y openvpn-systemd-resolved || true
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
if [ -d "/usr/share/thinOS" ] && [ ! -f "/usr/share/thinOS/.gitmodules" ]; then
    sudo rm -rf /usr/share/thinOS
fi
if [ -d "/usr/share/thinOS/.git" ]; then
    sudo git -C /usr/share/thinOS checkout $BRANCH
    sudo git -C /usr/share/thinOS pull --recurse-submodules
else
    sudo git clone --recursive --branch $BRANCH https://github.com/LaswitchTech/thinOS.git /usr/share/thinOS
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
if [ -d "/usr/share/PyRDPConnect" ] && [ ! -f "/usr/share/PyRDPConnect/.gitmodules" ]; then
    sudo rm -rf /usr/share/PyRDPConnect
fi
if [ -d "/usr/share/PyRDPConnect/.git" ]; then
    sudo git -C /usr/share/PyRDPConnect checkout $BRANCH
    sudo git -C /usr/share/PyRDPConnect pull --recurse-submodules
else
    sudo git clone --recursive --branch $BRANCH https://github.com/LaswitchTech/PyRDPConnect.git /usr/share/PyRDPConnect
fi

# Create a gradient background image
log_step 5 "Creating a gradient background image..."
mkdir -p $HOME/.config/thinOS/backgrounds
convert -size 1920x1080 gradient:'#595959-#242829' $HOME/.config/thinOS/backgrounds/gradient.png

# Configure Openbox
log_step 6 "Configuring Openbox..."
sudo sed -i 's/^#user-session=.*/user-session=openbox/' /etc/lightdm/lightdm.conf
mkdir -p $HOME/.config
if [ -d $HOME/.config/openbox ]; then
    rm -r $HOME/.config/openbox
fi
ln -sfn /usr/share/thinOS/src/openbox $HOME/.config/openbox
ln -sfn /usr/share/thinOS/src/.xinitrc $HOME/.xinitrc
ln -sfn /usr/share/thinOS/src/.xinitrc $HOME/.xsession
mkdir -p $HOME/.themes
ln -sfn /usr/share/thinOS/src/thinOS $HOME/.themes/thinOS
ln -sfn /usr/share/thinOS/src/.Xdefaults $HOME/.Xdefaults

# Setup bash profile and aliases
log_step 7 "Setup bash profile and aliases..."
if [ -f $HOME/.bash_profile ]; then
    rm $HOME/.bash_profile
fi
ln -sfn /usr/share/thinOS/src/.bash_profile $HOME/.bash_profile
if [ -f $HOME/.bash_aliases ]; then
    rm $HOME/.bash_aliases
fi
ln -sfn /usr/share/thinOS/src/.bash_aliases $HOME/.bash_aliases

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
    mkdir -p $HOME/.config/gtk-3.0
    ln -sfn /usr/share/thinOS/src/gtk/settings.ini $HOME/.config/gtk-3.0/settings.ini
fi

# Firefox dark mode via user.js (source of truth in /usr/share/thinOS/src)
# First, ensure at least one Firefox ESR profile exists by launching it once headlessly.
if command -v firefox-esr >/dev/null 2>&1; then
    # If no profile directory or no *.default* profiles exist, start Firefox ESR once
    if [ ! -d "$HOME/.mozilla/firefox" ] || ! compgen -G "$HOME/.mozilla/firefox/*.default*" > /dev/null; then
        echo "Initializing Firefox ESR profile (headless run)..."
        firefox-esr --headless >/dev/null 2>&1 &
        FF_PID=$!
        # Give it a few seconds to create the default profile
        sleep 10
        # Try to stop Firefox cleanly, ignore errors if it's already exited
        kill "$FF_PID" 2>/dev/null || pkill -f firefox-esr || true
    fi
fi

# Now link user.js into all available default profiles (ESR and non-ESR)
if [ -f /usr/share/thinOS/src/firefox/user.js ]; then
    mkdir -p "$HOME/.mozilla/firefox"

    for FF_PROFILE in "$HOME"/.mozilla/firefox/*.default "$HOME"/.mozilla/firefox/*.default-*; do
        [ -d "$FF_PROFILE" ] || continue
        ln -sfn /usr/share/thinOS/src/firefox/user.js "$FF_PROFILE/user.js"
        echo "Linked Firefox user.js into: $FF_PROFILE"
    done
fi

# Additional Linux specific configurations
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    log_step "12a" "Configuring OpenVPN for Linux..."
    # Set capabilities on OpenVPN binaries to allow non-sudo binding to privileged ports
    sudo setcap 'cap_net_admin,cap_net_bind_service=+ep' /usr/share/PyRDPConnect/src/bin/openvpn/linux/arm64/openvpn
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

# Additional Raspberry Pi OS-specific configurations
if [ "$DISTRO" == "raspbian" ]; then
    log_step 14 "Configuring Raspberry Pi OS for desktop boot and multi-monitor support..."

    # Boot to desktop
    sudo raspi-config nonint do_boot_behaviour B4

    # Set WiFi country so the radio is allowed to transmit
    sudo raspi-config nonint do_wifi_country CA || true

    # Ensure WiFi is not disabled via config.txt overlay
    CFG=/boot/firmware/config.txt
    [ -f "$CFG" ] || CFG=/boot/config.txt
    sudo sed -i '/^dtoverlay=disable-wifi/d' "$CFG"

    # Make sure WiFi isn't blocked by rfkill
    sudo rfkill unblock wifi || true

    # Choose correct config path (Bookworm vs older)
    CFG=/boot/firmware/config.txt
    [ -f "$CFG" ] || CFG=/boot/config.txt

    # Enable multi-monitor HDMI support
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
