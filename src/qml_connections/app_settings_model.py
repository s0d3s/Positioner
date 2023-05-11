from PySide6.QtCore import QObject, Signal, Property
from PySide6.QtGui import QColor

from typing import Callable, Any

from .utils_model import UtilsModel

try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    from ..data_manager import DataManager

except ImportError:
    from src.data_manager import DataManager


def camel_case_to_snake(name: str):
    first = 0
    current = 0
    parts = []
    for current in range(len(name)):
        if name[current].isupper():
            parts.append(name[first:current].lower())
            first = current

    parts.append(name[first:current + 1].lower())

    return "_".join(parts)


class SettingsProperty(Property):
    """Subclass of properties directly related to app config(AppData)
    In QML use camelCase; in python and configs - snake_case
    All property of this type must:
      - trigger related signal(_{propName}Signal)
      - trigger data saving(DataManager().trigger_save(save_snapshots_data=False))
    """

    @staticmethod
    def get_signal_by_prop_name(source, prop_name):
        return getattr(source, f"_{prop_name}Signal")

    def __init__(self, prop_type: type, get_mod=None, set_mod=None,
                 post_set: Callable[[object, object, Any], None] = lambda self, owner, value: None):
        self.camel_name = "isNotSet"
        self.snake_name = "is_not_set"

        def get_value(_self):
            return getattr(_self._data_man.app_data, self.snake_name)

        def set_value(_self, value):
            setattr(_self._data_man.app_data, self.snake_name, value)

            # trigger_save
            _self._data_man.trigger_save(save_snapshots_data=False)

            # trigger signal
            self.get_signal_by_prop_name(_self, self.camel_name).emit()
            self.target_post_set(self, _self, value)

        self.prop_type = prop_type
        self.target_fget = get_value if get_mod is None else lambda _self: get_mod(get_value(_self))
        self.target_fset = set_value if set_mod is None else lambda _s, _v: set_value(_s, set_mod(_s, _v))
        self.target_post_set = post_set

    def __set_name__(self, owner, name):
        self.camel_name = name
        self.snake_name = camel_case_to_snake(name)

        super().__init__(
            self.prop_type,
            fget=self.target_fget,
            fset=self.target_fset,
            notify=self.get_signal_by_prop_name(owner, self.camel_name)
        )


class ColorProperty(SettingsProperty):
    def __init__(self):
        super().__init__(QColor,
                         lambda value: QColor(value),
                         lambda _, color: color.name(format=QColor.NameFormat.HexArgb))


class AutorunProperty(SettingsProperty):
    def __init__(self, prop_type: Any):
        super().__init__(prop_type,
                         post_set=lambda descriptor, owner, value: (
                             owner.handle_autorun(
                                add=owner.restoreFromSnapshotOnSystemStartup > -1 or owner.launchOnSystemStartup
                             )
                         ))


class AppSettingsModel(QObject):
    """ Wrapper around some app settings """

    _showMainWindowSignal = Signal()
    showMainWindow = SettingsProperty(bool)

    _appTitleSignal = Signal()
    appTitle = SettingsProperty(str)

    _appVersionStrSignal = Signal()
    appVersionStr = SettingsProperty(str)

    _appHomePageSignal = Signal()
    appHomePage = SettingsProperty(str)

    _firstSlotMainColorSignal = Signal()
    firstSlotMainColor = ColorProperty()

    _secondSlotMainColorSignal = Signal()
    secondSlotMainColor = ColorProperty()

    _thirdSlotMainColorSignal = Signal()
    thirdSlotMainColor = ColorProperty()

    _launchOnSystemStartupSignal = Signal()
    launchOnSystemStartup = AutorunProperty(bool)

    _startMinimizedSignal = Signal()
    startMinimized = AutorunProperty(bool)

    _restoreFromSnapshotOnSystemStartupSignal = Signal()
    restoreFromSnapshotOnSystemStartup = AutorunProperty(int) # TODO: change "Snapshot" to "Slot"

    def __init__(self):
        super().__init__()

        self._data_man = DataManager()
        self._utils = UtilsModel()

    def handle_autorun(self, add: bool = True):
        if add:
            self._utils.addToAutorunWithArguments(start_after_action=self.launchOnSystemStartup,
                                                  minimized=self.startMinimized,
                                                  restore_from_slot=self.restoreFromSnapshotOnSystemStartup,
                                                  restore_transition="STUB")
        else:
            self._utils.delete_from_autorun()
