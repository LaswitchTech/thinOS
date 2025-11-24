#!/usr/bin/env python3
# src/app/window.py
import base64
from typing import Optional, TYPE_CHECKING

from PyQt5.QtWidgets import (
    QMainWindow, QWidget, QGridLayout, QLabel, QLineEdit,
    QHBoxLayout, QFormLayout, QSpinBox, QComboBox, QCheckBox,
    QApplication,
)
from PyQt5.QtGui import QIcon, QPixmap
from PyQt5.QtCore import Qt

from app.helper import Helper
from app.ui import Form
from app.configuration import Configuration
from app.log import Log


if TYPE_CHECKING:
    # For type hints only, avoids circular import at runtime
    from app.application import Application

class Window(QMainWindow):
    """
    Main application window placeholder.
    """

    def __init__(
        self,
        helper: Optional[Helper] = None,
        configuration: Optional[Configuration] = None,
        logger: Optional[Log] = None,
    ):
        # Initialize parent
        super().__init__()

        # Retrieve the application instance
        self._app: Application = QApplication.instance()

        # Ensure Client is created after Application
        if self._app is None:
            raise RuntimeError("Client must be created after QApplication/Application.")

        # --- auto-wire from QApplication if not provided ---
        if helper is None or configuration is None or logger is None:
            # narrow the type for linters / IDEs
            # no runtime import to avoid circular imports
            helper = helper or self._app.helper          # type: ignore[attr-defined]
            configuration = configuration or self._app.configuration  # type: ignore[attr-defined]
            logger = logger or self._app.logger          # type: ignore[attr-defined]

        # Helper
        self._helper: Helper = helper

        # Configuration
        self._configuration: Configuration = configuration

        # Save any new defaults
        self._configuration.save()

        # Logger
        self._logger: Log = logger

    # ------------------------------------------------------------------
    # Callbacks / overrides
    # ------------------------------------------------------------------

    def reset(self):
        pass

    def show(self):
        self.init()
        super().show()
        self._configuration.show()

    def exit(self):
        self.close()

    # ------------------------------------------------------------------
    # UI helpers
    # ------------------------------------------------------------------

    def init(self):

        # Set window title and icon
        self.setWindowTitle(self._app.name)
        icon_path = self._helper.join(self._helper.get_path("icons"),"play-fill.ico")
        self.setWindowIcon(QIcon(icon_path) if self._helper.file_exists(icon_path) else QIcon())
        self.setObjectName(self._app.name)
