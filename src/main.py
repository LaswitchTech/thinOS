#!/usr/bin/env python3
# src/main.py

import sys
import os

from app.application import Application

def main():
    # Create application instance
    app = Application("thinOS", sys.argv)

    # Connect to update signal
    app.updating.connect(update)

    # Add configuration entries
    app.configuration.add("customize.window.logo_file", None, "picture", label="Logo File")
    app.configuration.add("customize.gradient_start", "#265162", "color", label="Gradient Start")
    app.configuration.add("customize.gradient_end", "#002136", "color", label="Gradient End")

    # Save any new defaults
    app.configuration.save()

    # Just show the configuration dialog and nothing else
    app.configuration.show()

    # When the dialog is closed (Save or Cancel), just exit
    sys.exit(0)

def update():

    # Retrieve the application instance
    app = Application.instance()

    # Regenerate gradient background based on current configuration
    start = app.configuration.get("customize.gradient_start") or "#265162"
    end = app.configuration.get("customize.gradient_end") or "#002136"
    resolution = app.helper.get_screen_resolution()
    app.helper.run(["convert", "-size", resolution, f"gradient:'{start}-{end}'", os.path.expanduser("~/.config/thinOS/backgrounds/gradient.png")])

    # Update Plymouth theme
    theme_src = app.helper.get_path("plymouth")
    theme_dst = "/usr/share/plymouth/themes/thinOS"
    app.helper.run(["sudo", "rm", "-rf", theme_dst])
    app.helper.run(["sudo", "cp", "-rf", theme_src, theme_dst])
    app.helper.run(["sudo", "plymouth-set-default-theme", "-R", "thinOS"])
    app.helper.run(["sudo", "update-initramfs", "-u"])

    # Reload the Openbox theme
    app.helper.run(["openbox --reconfigure"])

if __name__ == "__main__":
    main()
