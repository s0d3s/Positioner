from PySide6.QtCore import QObject, Slot
import version
import winreg
import main
import sys
import os

try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    from ..data_manager import DataManager
    DEF_ENTRYPOINT_PATH = sys.executable

except ImportError:
    from src.data_manager import DataManager
    DEF_ENTRYPOINT_PATH = f'{sys.executable}" "{os.path.abspath(main.__file__)}'

DEF_AUTORUN_KEY_NAME = version.exe_target_name
DEF_AUTORUN_KEY_PATH = "Software\\Microsoft\\Windows\\CurrentVersion\\Run"


class UtilsModel(QObject):
    """Place for holding some utils

    Contain functions to with peripheral, like register edit, etc.
    """
    _aawa_available_args_map = {
        "start_after_action": {
            "key": "--exit",
            "reversed": True
        },
        "minimized": {
            "key": "--min"
        },
        "restore_from_slot": {
            "key": "--restore-slot",
            "value": "%s",
            "validator": lambda arg: arg > -1
        },
        "restore_transition": {
            "key": "--restore-transition",
            "value": "%s"
        },
    }

    def __init__(self):
        super().__init__()

        self._data_man = DataManager()

    @Slot(bool, bool, int, None)
    def addToAutorunWithArguments(self, start_after_action: bool = False, minimized: bool = False,
                                  restore_from_slot: int = -1, restore_transition=None):
        return self.add_2_autorun_with_arguments(
            start_after_action=start_after_action,
            minimized=minimized,
            restore_from_slot=restore_from_slot,
            restore_transition=restore_transition
        )

    def add_2_autorun_with_arguments(self, **kwargs):
        run_exe_cmd = f'"{DEF_ENTRYPOINT_PATH}"'
        for param, arg in kwargs.items():
            if param in self._aawa_available_args_map:
                passed_validation = bool(arg)\
                    if "validator" not in self._aawa_available_args_map[param]\
                    else self._aawa_available_args_map[param]["validator"](arg)
                if passed_validation ^ self._aawa_available_args_map[param].get("reversed", False):
                    run_exe_cmd += f" {self._aawa_available_args_map[param]['key']}"\
                                   + (f"={value % arg}" if (value:=self._aawa_available_args_map[param]
                                                            .get("value", None)) is not None else "")

        reg = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            DEF_AUTORUN_KEY_PATH,
            0,
            winreg.KEY_ALL_ACCESS
        )

        try:
            winreg.SetValueEx(reg, DEF_AUTORUN_KEY_NAME, 0, winreg.REG_SZ, run_exe_cmd)

        finally:
            winreg.CloseKey(reg)

    def delete_from_autorun(self):
        reg = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            DEF_AUTORUN_KEY_PATH,
            0,
            winreg.KEY_ALL_ACCESS
        )

        try:
            winreg.DeleteValue(reg, DEF_AUTORUN_KEY_NAME)

        except FileNotFoundError:
            ...
        finally:
            winreg.CloseKey(reg)


    def activate_snapshot(self, snap_ind: int, transition, **kwargs):
        self._data_man.activate_snapshot(snap_ind, transition=transition, **kwargs)

    def activate_from_slot(self, slot_ind: int, transition, **kwargs):
        self.activate_snapshot(self._data_man.app_data.get_slot_binding(slot_ind), transition, **kwargs)

    def create_new_snapshot(self):
        self._data_man._unshift_new_snapshot()

    def create_snapshot_and_attach_to(self, slot_ind: int):
        self.create_new_snapshot()
        self._data_man.app_data.attach_snap_to_slot(slot_ind, 0)
        self._data_man.app_data.recalc_slots_state()
        self._data_man.trigger_save(immediately=True)
