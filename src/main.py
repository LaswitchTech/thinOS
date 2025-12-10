#!/usr/bin/env python3
# src/main.py

import sys
import os

from core.application import Application
from core.cli import CommandLine

# ---------------------------------------------------------------------------
# Customization and start of the application
# ---------------------------------------------------------------------------

name = "thinOS"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def has_option():
    return any(arg.startswith('--') for arg in sys.argv)

# ---------------------------------------------------------------------------
# Start of the application
# ---------------------------------------------------------------------------

def start_app():
    app = Application(name,sys.argv)

    def reload():
        start = app.configuration.get("customize.gradient_start") or "#265162"
        end = app.configuration.get("customize.gradient_end") or "#002136"
        resolution = app.helper.get_screen_resolution()
        if resolution == (0, 0):
            resolution_str = "1920x1080"
        else:
            resolution_str = f"{resolution[0]}x{resolution[1]}"
        gradient_path = os.path.expanduser("~/.config/thinOS/backgrounds/gradient.png")

        # Create backgrounds directory if it doesn't exist
        os.makedirs(os.path.dirname(gradient_path), exist_ok=True)

        app._run_system_command(
            ["convert", "-size", resolution_str, f"gradient:{start}-{end}", gradient_path],
            wait=True,  # we probably want the image finished before setting it
        )
        app._run_system_command(
            ["feh", "--bg-scale", gradient_path],
            wait=True,  # this one can be async if you like
        )

    def update(do):
        start = app.configuration.get("customize.gradient_start") or "#595959"
        end = app.configuration.get("customize.gradient_end") or "#242829"
        resolution = app.helper.get_screen_resolution()
        if resolution == (0, 0):
            resolution_str = "1920x1080"
        else:
            resolution_str = f"{resolution[0]}x{resolution[1]}"

        gradient_path = os.path.expanduser("~/.config/thinOS/backgrounds/gradient.png")
        os.makedirs(os.path.dirname(gradient_path), exist_ok=True)

        # 1) gradient
        do(
            ["convert", "-size", resolution_str, f"gradient:{start}-{end}", gradient_path],
            f"Generating background ({resolution_str})…",
        )

        # 2) wallpaper
        do(
            ["feh", "--bg-scale", gradient_path],
            "Applying desktop background…",
        )

        # 3) openbox
        do(
            ["openbox", "--reconfigure"],
            "Reloading window manager…",
        )

        # 4) Plymouth theme
        theme_src = app.helper.get_path("plymouth")
        theme_dst = "/usr/share/plymouth/themes/thinOS"

        do(
            ["sudo", "rm", "-rf", theme_dst],
            "Removing old Plymouth theme…",
        )
        do(
            ["sudo", "cp", "-rf", theme_src, theme_dst],
            "Installing new Plymouth theme…",
        )
        do(
            ["sudo", "plymouth-set-default-theme", "-R", "thinOS"],
            "Setting default Plymouth theme…",
        )
        do(
            ["sudo", "update-initramfs", "-u"],
            "Rebuilding initramfs…",
        )

    def connect():
        # Only attempt WiFi configuration on Linux
        if app.helper.get_os() != "linux":
            return

        # Only attempt WiFi configuration on ARM64
        if app.helper.get_arch() != "arm64":
            return

        ssid = app.configuration.get("wifi.ssid")
        passphrase = app.configuration.get("wifi.passphrase")

        # Nothing to do if SSID is not configured
        if not ssid:
            return

        # Ensure WiFi radio is enabled
        app._run_system_command(
            ["nmcli", "radio", "wifi", "on"],
            wait=True,
        )

        # Build nmcli command to connect wlan0
        cmd = ["nmcli", "dev", "wifi", "connect", ssid, "ifname", "wlan0"]
        if passphrase:
            cmd += ["password", passphrase]

        # Run the connection command synchronously so we know when it's done
        app._run_system_command(
            cmd,
            wait=True,
        )

    # Connect to update signal
    app.updating.connect(update)
    app.configuration.configChanged.connect(reload)

    # Add configuration entries
    if(app.helper.get_os() == "linux" and app.helper.get_arch() == "arm64"):
        app.configuration.label("wifi", "WiFi")
        app.configuration.add("wifi.ssid", None, "wifi", label="SSID")
        app.configuration.add("wifi.passphrase", None, "password")
        app.configuration.configChanged.connect(connect)
    app.configuration.add("customize.logo_file", None, "picture", label="Logo File")
    app.configuration.add("customize.gradient_start", "#595959", "color", label="Gradient Start")
    app.configuration.add("customize.gradient_end", "#242829", "color", label="Gradient End")

    # Save any new defaults
    app.configuration.save()

    # Just show the configuration dialog and nothing else
    app.configuration.show()

    # When the dialog is closed (Save or Cancel), just exit
    sys.exit(0)

def start_cli():
    cli = CommandLine(name,sys.argv)

    # All other code gets app via QApplication.instance()
    sys.exit(cli.exec())

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if has_option():
        start_cli()
    else:
        start_app()
