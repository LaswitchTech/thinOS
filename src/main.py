#!/usr/bin/env python3
# src/main.py

import sys
import os

from app.application import Application

def main():

    # Create application instance
    app = Application("thinOS", sys.argv)



    def reload():

        # Regenerate gradient background based on current configuration
        start = app.configuration.get("customize.gradient_start") or "#265162"
        end = app.configuration.get("customize.gradient_end") or "#002136"
        resolution = app.helper.get_screen_resolution()
        app._run_system_command(["convert", "-size", resolution, f"gradient:'{start}-{end}'", os.path.expanduser("~/.config/thinOS/backgrounds/gradient.png")])
        app._run_system_command(["feh", "--bg-scale", os.path.expanduser("~/.config/thinOS/backgrounds/gradient.png")])

        # Reload the Openbox theme
        app._run_system_command(["openbox --reconfigure"])

    def update():

        # Reload gradient background
        reload()

        # Update Plymouth theme
        theme_src = app.helper.get_path("plymouth")
        theme_dst = "/usr/share/plymouth/themes/thinOS"
        app._run_system_command(["sudo", "rm", "-rf", theme_dst])
        app._run_system_command(["sudo", "cp", "-rf", theme_src, theme_dst])
        app._run_system_command(["sudo", "plymouth-set-default-theme", "-R", "thinOS"])
        app._run_system_command(["sudo", "update-initramfs", "-u"])

    # Connect to update signal
    app.updating.connect(update)
    app.configuration.configChanged.connect(reload)

    # Add configuration entries
    app.configuration.add("customize.logo_file", None, "picture", label="Logo File")
    app.configuration.add("customize.gradient_start", "#265162", "color", label="Gradient Start")
    app.configuration.add("customize.gradient_end", "#002136", "color", label="Gradient End")

    # Save any new defaults
    app.configuration.save()

    # Just show the configuration dialog and nothing else
    app.configuration.show()

    # When the dialog is closed (Save or Cancel), just exit
    sys.exit(0)

if __name__ == "__main__":
    main()
