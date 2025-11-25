#!/usr/bin/env python3
# src/app/application.py
from __future__ import annotations

from typing import Optional, Iterable
from PyQt5.QtCore import pyqtSignal, Qt
from PyQt5.QtWidgets import QProxyStyle, QStyle, QApplication, QProgressDialog, QPushButton

from .helper import Helper
from .configuration import Configuration
from .log import Log
from .ui import MsgBox
import os
import subprocess

# ---------------------------------------------------------------------------
# Custom Style to suppress focus rectangles
# ---------------------------------------------------------------------------

class NoFocusRectStyle(QProxyStyle):
    def drawPrimitive(self, element, option, painter, widget=None):
        if element == QStyle.PE_FrameFocusRect:
            return  # skip drawing the focus rect completely
        super().drawPrimitive(element, option, painter, widget)



# ---------------------------------------------------------------------------
# Application update dialog
# ---------------------------------------------------------------------------

class ApplicationDialog(QProgressDialog):
    canceled_by_user = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__("Updating...", "Cancel", 0, 0, parent)
        self.setWindowModality(Qt.WindowModal)
        self.setWindowFlags(
            Qt.Dialog | Qt.WindowTitleHint
            | Qt.CustomizeWindowHint | Qt.WindowCloseButtonHint
        )
        self.setObjectName("ApplicationDialog")
        self.setMinimumDuration(0)
        self.setAutoReset(False)
        self.setFixedWidth(300)

        # Replace default Cancel button with our own so we can style it if needed
        btn = QPushButton("Cancel", self)
        btn.clicked.connect(self._on_cancel)
        self.setCancelButton(btn)

    def _on_cancel(self):
        self.canceled_by_user.emit()
        self.reject()

# ---------------------------------------------------------------------------
# Application class
# ---------------------------------------------------------------------------

class Application(QApplication):

    updating = pyqtSignal()

    def __init__(self, name: Optional[str] = None, argv=None):

        # Initialize QApplication
        super().__init__(argv or [])

        # Application name
        if name:
            self.setApplicationName(name)

        # Set application style
        self.setStyle('Fusion')

        # Use custom style to suppress focus rectangles
        self.setStyle(NoFocusRectStyle(self.style()))

        # Main window placeholder (e.g. Client)
        self._mainWindow = None

        # Helper
        self._helper = Helper()

        # Configuration manager
        self._configuration = Configuration()
        self._configuration.configChanged.connect(self.reset)

        # Default configuration entries
        self._configuration.add("administration.update", None, "button", label="Check for Updates", action=self.update)

        # Save any new defaults
        self._configuration.save()

        # Logger
        self._logger = Log()

        # Initial stylesheet load
        self._loadStylesheet()

    # ------------------------------------------------------------------
    # Properties / accessors
    # ------------------------------------------------------------------

    @property
    def helper(self) -> Helper:
        return self._helper

    @property
    def logger(self) -> Log:
        return self._logger

    @property
    def configuration(self) -> Configuration:
        return self._configuration

    @property
    def mainWindow(self):
        return self._mainWindow

    @property
    def name(self) -> str:
        return self.applicationName()

    # ------------------------------------------------------------------
    # Main window management
    # ------------------------------------------------------------------

    def set_mainWindow(self, window):
        self._mainWindow = window
        self._loadStylesheet()
        self._mainWindow.show()

    # ------------------------------------------------------------------
    # Stylesheet handling
    # ------------------------------------------------------------------

    def _loadStylesheet(self):

        # Base stylesheet (e.g. styles/style.css)
        base_css = self._helper.load_stylesheet("styles/style.css")  # you can implement this in Helper

        # Retrieve icon paths
        check_svg = self._helper.get_path("icons/check.svg")
        chevron_up_svg = self._helper.get_path("icons/chevron-up.svg")
        chevron_down_svg = self._helper.get_path("icons/chevron-down.svg")
        chevron_expand_svg = self._helper.get_path("icons/chevron-expand.svg")

        # Override styles
        override = (
            "\n"
            "QCheckBox::indicator:checked { "
            f"image: {self._helper.qss_url(check_svg)};"
            " }\n"
            "QComboBox::down-arrow { "
            f"image: {self._helper.qss_url(chevron_expand_svg)};"
            " }\n"
            "QSpinBox::up-arrow { "
            f"image: {self._helper.qss_url(chevron_up_svg)};"
            " }\n"
            "QSpinBox::down-arrow { "
            f"image: {self._helper.qss_url(chevron_down_svg)};"
            " }\n"
        )

        # Start with base + global overrides
        css = (base_css or "") + override

        # If main window has its own override, append it
        if self._mainWindow and hasattr(self._mainWindow, "override"):
            css += self._mainWindow.override()

        # Apply combined stylesheet
        self.setStyleSheet(css)

    # ------------------------------------------------------------------
    # UI reset on configuration change
    # ------------------------------------------------------------------

    def reset(self):

        # Do nothing if no main window
        if not self._mainWindow:
            return

        # Call main window reset if available
        if hasattr(self._mainWindow, 'reset'):
            self._loadStylesheet()
            self._mainWindow.reset()

    # ------------------------------------------------------------------
    # System Helpers
    # ------------------------------------------------------------------

    def _run_system_command(self, args: list[str], wait: bool = False) -> int | None:

        # Only attempt on Linux; ignore silently on other platforms
        try:
            os_name = self._helper.get_os()
        except Exception:
            os_name = None

        if os_name != "linux":
            if self._logger:
                self._logger.append(
                    f"[Application] Ignoring system command {args!r} on non-Linux OS: {os_name}",
                    channel="system",
                    level="warning",
                )
            return None

        try:
            if wait:
                proc = subprocess.Popen(args)
                rc = proc.wait()
                if self._logger:
                    self._logger.append(
                        f"[Application] (wait) Command finished ({rc}): {' '.join(args)}",
                        channel="system",
                        level="info",
                    )
                return rc
            else:
                subprocess.Popen(args)
                if self._logger:
                    self._logger.append(
                        f"[Application] Executed system command: {' '.join(args)}",
                        channel="system",
                        level="info",
                    )
                return None
        except Exception as e:
            if self._logger:
                self._logger.append(
                    f"[Application] Failed to execute system command {args!r}: {e}",
                    channel="system",
                    level="error",
                )
            return None

    def shutdown(self) -> None:
        self._run_system_command(["systemctl", "poweroff"])

    def restart(self) -> None:
        self._run_system_command(["systemctl", "reboot"])

    # ------------------------------------------------------------------
    # Application Helpers
    # ------------------------------------------------------------------

    def update(self):
        # Determine repo root based on this file location
        try:
            here = os.path.abspath(os.path.dirname(__file__))
            repo_root = os.path.abspath(os.path.join(here, "..", ".."))
        except Exception as e:
            if self._logger:
                self._logger.append(
                    f"[Application] Failed to determine repository root for update: {e}",
                    channel="system",
                    level="error",
                )
            MsgBox.show(
                parent=self._mainWindow,
                title="Update Failed",
                message="Failed to determine the repository root for the update.",
                icon="error",
                buttons=("OK",),
                default="OK",
                icon_lookup_fn=self._helper.get_path,
            )
            return

        # Create and show the progress dialog so the user sees that the update is in progress
        dlg_parent = self._mainWindow if self._mainWindow is not None else None
        progress = ApplicationDialog(parent=dlg_parent)
        progress.setLabelText(f"Updating {self.name}...")
        progress.setRange(0, 0)  # Busy indicator

        cancel_state = {"canceled": False}

        def handle_cancel():
            cancel_state["canceled"] = True

        progress.canceled_by_user.connect(handle_cancel)
        progress.show()
        self.processEvents()

        # Only attempt on Linux; ignore silently on other platforms
        try:
            os_name = self._helper.get_os()
        except Exception:
            os_name = None

        if os_name != "linux":
            if self._logger:
                self._logger.append(
                    "[Application] Update ignored on non-Linux OS.",
                    channel="system",
                    level="warning",
                )
            progress.close()
            MsgBox.show(
                parent=self._mainWindow,
                title="Update Not Available",
                message="Updating is only supported on Linux systems.",
                icon="info",
                buttons=("OK",),
                default="OK",
                icon_lookup_fn=self._helper.get_path,
            )
            return

        # Start the git pull process
        try:
            proc = subprocess.Popen(["sudo", "git", "-C", repo_root, "pull"])
        except Exception as e:
            if self._logger:
                self._logger.append(
                    f"[Application] Failed to start update process: {e}",
                    channel="system",
                    level="error",
                )
            progress.close()
            MsgBox.show(
                parent=self._mainWindow,
                title="Update Failed",
                message=f"Failed to start the update process:\n{e}",
                icon="error",
                buttons=("OK",),
                default="OK",
                icon_lookup_fn=self._helper.get_path,
            )
            return

        # Poll the process while keeping the UI responsive and checking for cancel requests
        rc = None
        while True:
            rc = proc.poll()
            if rc is not None:
                break
            if cancel_state["canceled"]:
                try:
                    proc.terminate()
                except Exception:
                    pass
                rc = proc.wait()
                break
            # Keep the GUI responsive
            self.processEvents()

        if self._logger:
            self._logger.append(
                f"[Application] Update command finished ({rc}): sudo git -C {repo_root} pull",
                channel="system",
                level="info" if rc == 0 else "error",
            )

        progress.close()

        # If user canceled, do not proceed with post-update tasks
        if cancel_state["canceled"]:
            MsgBox.show(
                parent=self._mainWindow,
                title="Update Canceled",
                message="The update was canceled. The application may not be fully up to date.",
                icon="warning",
                buttons=("OK",),
                default="OK",
                icon_lookup_fn=self._helper.get_path,
            )
            return

        # Non-zero exit → error
        if rc not in (0, None):
            MsgBox.show(
                parent=self._mainWindow,
                title="Update Failed",
                message=f"Update failed with exit code {rc}. Check the logs for details.",
                icon="error",
                buttons=("OK",),
                default="OK",
                icon_lookup_fn=self._helper.get_path,
            )
            return

        # Emit signal that update has occurred, so external code can do extra tasks
        self.updating.emit()

        # Notify user to restart application
        buttons: Iterable[str] = ("Exit", "OK")
        choice = MsgBox.show(
            parent=self._mainWindow,
            title="Update Successful",
            message="The application has been updated. Please restart the application to apply the latest changes.",
            icon="info",
            buttons=buttons,
            default="OK",
            icon_lookup_fn=self._helper.get_path,
        )

        if choice == "Exit":
            self.quit()
