#!/usr/bin/env python3
# src/main.py

import sys
import os

from app.application import Application

def main():

    # Create application instance
    app = Application("thinOS", sys.argv)

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
        start = app.configuration.get("customize.gradient_start") or "#76797c"
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

    # Connect to update signal
    app.updating.connect(update)
    app.configuration.configChanged.connect(reload)

    # Add configuration entries
    if(app.helper.get_os() == "linux"):
        app.configuration.label("wifi", "WiFi")
        app.configuration.add("wifi.ssid", None, "text", label="SSID")
        app.configuration.add("wifi.passphrase", None, "password")
    app.configuration.add("customize.logo_file", None, "picture", label="Logo File")
    app.configuration.add("customize.gradient_start", "#76797c", "color", label="Gradient Start")
    app.configuration.add("customize.gradient_end", "#242829", "color", label="Gradient End")

    # Save any new defaults
    app.configuration.save()

    # Just show the configuration dialog and nothing else
    app.configuration.show()

    # When the dialog is closed (Save or Cancel), just exit
    sys.exit(0)

if __name__ == "__main__":
    main()
