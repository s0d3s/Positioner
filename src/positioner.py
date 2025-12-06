from PySide6 import Path, QtCore
from PySide6.QtGui import QAction, QCursor
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QtMsgType

import PySide6.QtWidgets as QtWidgets
import PySide6.QtGui as QtGui
import sys

import version

from src.qml_connections import snapshots_list_model, desktop_flags_model, app_settings_model, utils_model
from src.logger import LogLevel, logger

def qt_message_handler(mode, context, message):
    qt_log_level_map = {
        QtMsgType.QtDebugMsg: LogLevel.DEBUG,
        QtMsgType.QtInfoMsg: LogLevel.INFO,
        QtMsgType.QtWarningMsg: LogLevel.WARNING,
        QtMsgType.QtCriticalMsg: LogLevel.ERROR,
        QtMsgType.QtFatalMsg: LogLevel.CRITICAL,
    }
    correct_level = qt_log_level_map.get(mode, LogLevel.DEBUG)

    def get_right_name_part(path: str) -> str:
        return path.rsplit("/", 1)[-1]
    
    logger.opt(depth=1).log(
        correct_level,
        f"{message} ({get_right_name_part(context.file)}:{context.line})"
    )


def run_gui(start_minimized=False):
    ui_dir_path = Path(__file__).parent / "positioner_ui"

    QtCore.qInstallMessageHandler(qt_message_handler)
    app = QtWidgets.QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)

    app_icon = QtGui.QIcon(str(ui_dir_path / "assets" / "favicon_positioner.ico"))
    app.setWindowIcon(app_icon)

    QtGui.QFontDatabase.addApplicationFont(str(ui_dir_path / "fonts" / "Orbitron.ttf"))

    engine = QQmlApplicationEngine()

    s_l_m = snapshots_list_model.SnapshotsListModel()
    d_f_m = desktop_flags_model.DesktopFlagsModel()
    a_s_m = app_settings_model.AppSettingsModel()
    a_s_m.showMainWindow = not (start_minimized or a_s_m.startMinimized)
    a_s_m.appVersionStr = f"v{version.version}"
    a_s_m.appHomePage = version.home_page
    utils_m = utils_model.UtilsModel()

    root_context = engine.rootContext()
    root_context.setContextProperty("snapshotsListModel", s_l_m)
    root_context.setContextProperty("desktopFlagsModel", d_f_m)
    root_context.setContextProperty("appSettingsModel", a_s_m)
    root_context.setContextProperty("utilsModel", utils_m)

    # Tray icon

    tray = QtWidgets.QSystemTrayIcon()
    tray.setIcon(app_icon)
    tray.setVisible(True)

    menu = QtWidgets.QMenu()

    temp_list = [] # addAction steal ref

    toggle_eye = QAction("Toggle 👁")
    toggle_eye.triggered.connect(lambda: s_l_m.hideShowButtonClicked())
    menu.addAction(toggle_eye)

    for i in range(3):
        action = QAction(f"Restore #{i+1}")
        action.triggered.connect(lambda _=None, ind=i: s_l_m.restoreSnapshotFromSlot(ind))
        temp_list.append(action)
        menu.addAction(action)

    quit = QAction("Quit")
    quit.triggered.connect(app.quit)
    menu.addAction(quit)
    
    def show_main_window(reason):
        if reason == tray.ActivationReason.Trigger:
            setattr(a_s_m, "showMainWindow", False)
            setattr(a_s_m, "showMainWindow", True)
        elif reason == tray.ActivationReason.Context:
            # Right click → show context menu
            tray_and_menu_height = 145
            pos = QCursor.pos()
            pos.setY(pos.y() - tray_and_menu_height)  # slight offset
            menu.popup(pos)

    tray.activated.connect(show_main_window)

    qml_file = ui_dir_path / "App.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    
    logger.trace("GUI prepared, entering main loop")
    code = app.exec()
    logger.trace("Exiting GUI main loop. Code: {}", code)
    utils_m._data_man.prepare_exit()
    sys.exit(code)


if __name__ == "__main__":
    run_gui()
