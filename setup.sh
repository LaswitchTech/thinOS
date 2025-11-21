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
    sudo apt-get full-upgrade -y
    sudo apt-get upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt full-upgrade -y
else
    echo "Unsupported distribution: $DISTRO"
    exit 1
fi

# Install necessary packages based on the distribution
log_step 2 "Installing a Minimal Desktop Environment, Git, Firefox, ImageMagick, and feh..."
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y \
        lightdm \
        openbox \
        git \
        xterm \
        firefox-esr \
        plymouth \
        plymouth-themes \
        imagemagick \
        feh \
        freerdp2-x11 \
        python3 \
        python3-pyqt5 \
        python3-pyqt5* \
        wireguard-tools \
        openvpn \
        obconf
else
    echo "Unsupported distribution: $DISTRO"
    exit 1
fi

# Install or update the thinOS repository in /usr/share
log_step 3 "Installing or updating thinOS in /usr/share..."
if [ -d "/usr/share/thinOS/.git" ]; then
    sudo git -C /usr/share/thinOS pull
else
    sudo git clone https://github.com/LaswitchTech/thinOS.git /usr/share/thinOS
fi

# Install or update the PyRDPConnect repository in /usr/share
log_step 4 "Installing or updating the PyRDPConnect repository in /usr/share..."
if [ -d "/usr/share/PyRDPConnect/.git" ]; then
    sudo git -C /usr/share/PyRDPConnect pull
else
    sudo git clone https://github.com/LaswitchTech/PyRDPConnect.git /usr/share/PyRDPConnect
fi

# Create a gradient background image
log_step 5 "Creating a gradient background image..."
mkdir -p ~/backgrounds
convert -size 1920x1080 gradient:'#265162-#002136' ~/backgrounds/gradient.png

# Configure Openbox
log_step 6 "Configuring Openbox..."
sudo sed -i 's/^#user-session=.*/user-session=openbox/' /etc/lightdm/lightdm.conf
mkdir -p ~/.config
sudo ln -sfn /usr/share/thinOS/src/openbox ~/.config/openbox

# Set Openbox to start automatically
log_step 7 "Setting Openbox to start automatically..."
sudo ln -sfn /usr/share/thinOS/src/.xinitrc ~/.xinitrc
sudo ln -sfn /usr/share/thinOS/src/.xinitrc ~/.xsession

# Import Openbox theme
mkdir -p ~/.themes
sudo ln -sfn /usr/share/thinOS/src/thinOS ~/.themes/thinOS

# Link .Xdefaults for xterm configuration
sudo ln -sfn /usr/share/thinOS/src/.Xdefaults ~/.Xdefaults

# Set locale and timezone
log_step 8 "Setting locale and timezone..."
sudo sed -i '/en_GB.UTF-8/s/^/#/' /etc/locale.gen
sudo sed -i '/en_CA.UTF-8/s/^# //g' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_CA.UTF-8
sudo timedatectl set-timezone America/Montreal

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
if [ -f "/boot/firmware/cmdline.txt" ]; then
    FILE=/boot/firmware/cmdline.txt
    sudo sed -i 's/console=tty1/console=tty3/' "$FILE"
    if ! grep -q "splash" "$FILE"; then
        echo "splash quiet plymouth.ignore-serial-consoles" | sudo tee -a "$FILE"
    fi
fi

# Copy and set custom Plymouth theme
log_step 11 "Setting the custom Plymouth theme..."
sudo ln -sfn /usr/share/thinOS/src/plymouth /usr/share/plymouth/themes/thinOS
sudo plymouth-set-default-theme -R thinOS
sudo update-initramfs -u

# Enable auto-login for Debian
if [ "$DISTRO" == "debian" ]; then
    log_step 12 "Enabling auto-login for Debian..."
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
    log_step 13 "Configuring Raspberry Pi OS for desktop boot and multi-monitor support..."

    # Set up Raspberry Pi to boot into the desktop environment
    sudo raspi-config nonint do_boot_behaviour B4

    if printf '%s\n' "$@" | grep -q -- --multimon; then
        # Enable HDMI output for both monitors
        sudo bash -c 'cat <<EOL >> /boot/firmware/config.txt
# For more options and information see
# http://rptl.io/configtxt
# Some settings may impact device functionality. See link above for details

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
#dtparam=spi=on

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Additional overlays and parameters are documented
# /boot/firmware/overlays/README

# Automatically load overlays for detected cameras
camera_auto_detect=1

# Automatically load overlays for detected DSI displays
display_auto_detect=1

# Automatically load initramfs files, if found
auto_initramfs=1

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Don't have the firmware create an initial video= setting in cmdline.txt.
# Use the kernel's default instead.
disable_fw_kms_setup=1

# Run in 64-bit mode
arm_64bit=1

# Enable HDMI output for both monitors
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1

# Set HDMI group and mode (adjust as necessary) 82 = 1080p
hdmi_group:0=2
hdmi_mode:0=82
hdmi_group:1=2
hdmi_mode:1=82

# Disable compensation for displays with overscan
disable_overscan=1

# Run as fast as firmware / board allows
arm_boost=1

[cm4]
# Enable host mode on the 2711 built-in XHCI USB controller.
# This line should be removed if the legacy DWC2 controller is required
# (e.g. for USB device mode) or if USB support is not required.
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host

[all]
disable_splash=1
EOL'
    fi
fi

log_step 14 "cleanup..."
# Remove setup script
if [ -f "$HOME/setup.sh" ]; then
    rm "$HOME/setup.sh"
fi
# Auto remove unused packages
if [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "debian" ]; then
    sudo apt-get autoremove -y
fi

# Final instructions
log_step 15 "Setup completed. Please reboot the system to apply the changes."
