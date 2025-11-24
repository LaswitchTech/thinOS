#!/usr/bin/env python3
# src/main.py

import sys

from app.application import Application

def main():
    app = Application("thinOS", sys.argv)

    # Just show the configuration dialog and nothing else
    app.configuration.show()

    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
