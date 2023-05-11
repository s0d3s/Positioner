from dataclasses import dataclass, field, asdict, fields
from typing import Dict, Union, List, Optional, Any, Callable, Tuple
from threading import Thread, Event
from abc import abstractmethod

import os
import sys
import time
import json


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# If this is a release build, c_part will be already visible
try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    DEF_ENTRYPOINT_DIR = os.path.dirname(os.path.abspath(sys.executable))
    RELEASE_SRC_DIR = os.path.abspath(
        os.path.join(SCRIPT_DIR, '../../src')
    )
    sys.path.append(RELEASE_SRC_DIR)
    from movement_transitions import collect_available_transitions

except ImportError:
    ROOT_DIR = os.path.abspath(
        os.path.join(
            SCRIPT_DIR,
            ".."
        )
    )
    BUILD_LIB_DIR = os.path.join(ROOT_DIR, 'build_pcp')
    sys.path.append(BUILD_LIB_DIR)
    DEF_ENTRYPOINT_DIR = os.path.split(SCRIPT_DIR)[0]
    from src.movement_transitions import collect_available_transitions

import positioner_c_part as pcp


HIDE_SHOW_RESTORE_POINT = "RestorePoint"
HIDE_SHOW_HIDDEN_POINT = "HiddenPoint"

FWF_NOICONS = 0x1000
FWF_HIDEFILENAMES = 0x20000
FWF_SNAPTOGRID = 0x4
CLEAR_BIT_MASK = 0xffffffff
MASK_OFF_FLAGS_ON_HIDE = CLEAR_BIT_MASK ^ FWF_SNAPTOGRID

DEFAULT_ATTEMPTS_TO_BYPASS_WIN_TIMEOUT = 20


class JSONSerializable:
    @abstractmethod
    def as_dict(self):
        ...


class DataManagerJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, JSONSerializable):
            return o.as_dict()
        return super().default(o)


@dataclass
class SnapshotData(JSONSerializable):
    snapshot_hash: str
    snapshot_name: str
    snapshot_date: int
    desktop_flags: int

    # snapshot of icons positions
    # {"PIDL_N": {
    #               'display_name': str,
    #               'path': str,         # may be empty
    #               'is_virtual': bool,  # if this is icon of virtual folder
    #               'x': int,
    #               'y': int
    #             }
    # }
    icons_snapshot: Dict[str, Dict[str, Union[str, int, bool]]]

    # if private snapshot
    snapshot_locked: bool = field(default=False)

    def as_dict(self):
        return asdict(self)


@dataclass
class AppDataStaticProperties:
    show_main_window: str = True

    app_title: str = "Positioner"
    app_version_str: str = "v91.91.91"
    app_home_page: str = "https://github.com"


@dataclass
class AppDataSettingProperties(JSONSerializable):

    # duplicate of  AppData.slots_bindings
    slots_bindings: List[Union[str, None]] = field(default_factory=list)

    # ARGB
    first_slot_main_color: str = "#FF7DD6E8"
    second_slot_main_color: str = "#FF96B5FF"
    third_slot_main_color: str = "#FF977DE8"

    launch_on_system_startup: bool = False
    start_minimized: bool = False
    restore_from_snapshot_on_system_startup: int = -1

    def as_dict(self):
        return {prop.name: (value if (value := getattr(self, prop.name)) is not None else prop.default)
                for prop in fields(AppDataSettingProperties)}


@dataclass
class AppData(AppDataSettingProperties, AppDataStaticProperties):

    # call it when data changed
    on_change_trigger: Callable[[bool, bool, bool], None] = lambda _, __, ___: None

    # Link to the list of snapshots data
    snapshots_data: List[SnapshotData] = field(repr=False, default_factory=list)

    # bind slot index(num) to snapshot hash
    # for more accurate session restoring
    slots_bindings: List[Union[str, None]] = field(default_factory=list)

    # bind snapshot hash to snapshot 'index'
    snapshots_bindings: List[int] = field(default_factory=list)

    # indicates if snapshot, which attached to slot, is active
    slots_state: List[bool] = field(default_factory=list)

    # This button hides or shows the desktop icons
    # while pulling them into one point
    # If icons are hidden:
    #  - exist two snapshots[index]:
    #    [-1] snapshot_name=HIDE_SHOW_RESTORE_POINT
    #    [-2] snapshot_name=HIDE_SHOW_HIDDEN_POINT
    #  - set Desktop Flag FWF_SNAPTOGRID | (Optional)FWF_NOICONS
    # Snapshots are deleted when restored
    hide_show_button_active = False

    slots_count = 3

    def get_hide_show_button_active(self) -> bool:
        return self.hide_show_button_active

    def hide_show_button_snapshots(self) -> Tuple[Union[SnapshotData, None], Union[SnapshotData, None]]:
        if len(self.snapshots_data)>1:
            snap_last = self.snapshots_data[-1]
            snap_pre_last = self.snapshots_data[-2]
            if (snap_last.snapshot_name==HIDE_SHOW_RESTORE_POINT and
                    snap_pre_last.snapshot_name==HIDE_SHOW_HIDDEN_POINT and
                    snap_last.snapshot_locked and snap_pre_last.snapshot_locked):
                return snap_last, snap_pre_last
        return None, None

    def check_hide_show_button(self) -> None:
        self.hide_show_button_active = None not in self.hide_show_button_snapshots()

    def recalc_snapshots_bindings(self, snapshot_hashes: List[str]) -> None:
        self.snapshots_bindings = [-2 for _ in range(self.slots_count)]

        assert len(self.slots_bindings) <= self.slots_count

        for slot_ind, exc_hash in enumerate(self.slots_bindings):
            if not exc_hash:
                continue
            for snap_ind, snap_hash in enumerate(snapshot_hashes):
                if exc_hash == snap_hash:
                    self.snapshots_bindings[slot_ind] = snap_ind
                    break

    def new_snapshot_unshifted(self) -> None:
        """Increase all `snapshots_bindings`"""
        self.snapshots_bindings = [
            snap_ind + 1 if snap_ind >= 0 else snap_ind
            for snap_ind in self.snapshots_bindings
        ]

    def set_slot_binding(self, slot_ind: int, value: int):
        self.snapshots_bindings[slot_ind] = value

    def get_slot_binding(self, slot_ind: int) -> int:
        return self.snapshots_bindings[slot_ind]

    def set_slot_state(self, slot_ind: int, value: bool):
        self.slots_state[slot_ind] = value

    def get_slot_state(self, slot_ind: int) -> bool:
        return self.slots_state[slot_ind]

    def attach_snap_to_slot(self, slot_ind: int, snap_ind: int):
        self.snapshots_bindings = [
            (snap_ind if slot_ind == curr_slot_ind else curr_snap_ind)
            if curr_snap_ind != snap_ind else -2
            for curr_slot_ind, curr_snap_ind in enumerate(self.snapshots_bindings)
        ]
        self.slots_bindings = [
            self.snapshots_data[curr_snap_ind].snapshot_hash
            if curr_snap_ind >= 0 else None
            for curr_snap_ind in self.snapshots_bindings
        ]
        self.on_change_trigger()

    def snapshot_was_removed(self, snapshot_hash: str, rem_snapshot_ind: int):
        """Update bindings"""
        for slot_ind, attached_hash in enumerate(self.slots_bindings):
            if attached_hash == snapshot_hash:
                self.slots_bindings[slot_ind] = None

        for slot_ind, attached_snap_ind in enumerate(self.snapshots_bindings):
            if attached_snap_ind >= 0 and attached_snap_ind > rem_snapshot_ind:
                self.snapshots_bindings[slot_ind] -= 1
            elif attached_snap_ind == rem_snapshot_ind:
                self.snapshots_bindings[slot_ind] = -2

    def recalc_slots_state(self) -> None:
        """
        A slot is considered active if:
         - there is at least one element
         - all existing elements are in the same places as in `current_state`
        """
        slots_state = [False for _ in self.snapshots_bindings]
        current_state = self.get_icons_data()

        for slot_ind, attached_snap_ind in enumerate(self.snapshots_bindings):
            is_active = False

            if attached_snap_ind >= 0:
                icons_snapshot = self.snapshots_data[attached_snap_ind]\
                    if attached_snap_ind<len(self.snapshots_data) else {}

                is_active = True
                icon_pidl: str
                icon_data: Dict[str, Any]
                for icon_pidl, icon_data in icons_snapshot.icons_snapshot.items():
                    current_icon_data = current_state.get(icon_pidl, None)
                    if (not current_icon_data
                            or current_icon_data.get("x", None) != icon_data.get("x", None)
                            or current_icon_data.get("y", None) != icon_data.get("y", None)):
                        is_active = False
                        break

            slots_state[slot_ind] = is_active
        self.slots_state = slots_state

    ##########

    @staticmethod
    def get_desktop_flags() -> int:
        return pcp.get_desktop_flags()

    @staticmethod
    def switch_desktop_flags(flag_code: int) -> int:
        return pcp.switch_desktop_flags(flag_code)

    @staticmethod
    def get_icons_data(*args, **kwargs) -> Dict[str, Dict]:
        for _ in range(DEFAULT_ATTEMPTS_TO_BYPASS_WIN_TIMEOUT):
            try:
                return pcp.get_icons_data(*args, **kwargs)

            except LookupError:
                time.sleep(0.005)

        raise OSError(f"Exceeded the number({DEFAULT_ATTEMPTS_TO_BYPASS_WIN_TIMEOUT})"
                      f" of attempts to bypass the WIN timeout")

    @staticmethod
    def set_icons_data(*args, **kwargs) -> List[str]:
        for _ in range(DEFAULT_ATTEMPTS_TO_BYPASS_WIN_TIMEOUT):
            try:
                return pcp.set_icons_data(*args, **kwargs)

            except LookupError:
                time.sleep(0.001)

        raise OSError(f"Exceeded the number({DEFAULT_ATTEMPTS_TO_BYPASS_WIN_TIMEOUT})"
                      f" of attempts to bypass the WIN timeout")


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


class DataManager(metaclass=Singleton):
    """
    Central storage/Desktop controller
    Provides an interface for manipulating persisted data
    Namely: App config/Icons Position Snapshots
    """
    _data_dir = os.path.join(DEF_ENTRYPOINT_DIR, "configs")
    _app_config_file = os.path.join(_data_dir, "app_config.json")
    _snapshots_data_file = os.path.join(_data_dir, "snapshots_data.json")
    _save_interval = 2 # in seconds

    screen_center = 500, 500

    def __init__(self):
        os.makedirs(self._data_dir, exist_ok=True)
        self.app_data: Optional[AppData] = None
        self.snapshots_data: List[SnapshotData] = []

        self._load_snapshots_data()
        self.save_manager_timer: Optional[Thread] = None
        self.save_manager_close_event = Event()

    def prepare_exit(self):
        if self.save_manager_timer is not None:
            if self.save_manager_timer.is_alive() and not self.save_manager_close_event.is_set():
                self.save_manager_close_event.set()
                self.save_manager_timer.join()

                self.save_manager_close_event.clear()
                self._save_all_data(save_app_data=True, save_snapshots_data=True, immediately=True)

    def hide_show_button_clicked(self):
        restore_snapshot: Optional[SnapshotData]
        hide_snapshot: Optional[SnapshotData]
        restore_snapshot, hide_snapshot = self.app_data.hide_show_button_snapshots()

        created: bool = True

        if restore_snapshot is None:
            # Icons are visible. Hide them
            restore_snapshot: Dict = self.app_data.get_icons_data()
            hide_snapshot: Dict = {}
            for icon in restore_snapshot:
                hide_snapshot[icon] = restore_snapshot[icon].copy()
                hide_snapshot[icon]["x"], hide_snapshot[icon]["y"] = self.screen_center

            current_flags = self.app_data.get_desktop_flags()

            hide_flags = current_flags & MASK_OFF_FLAGS_ON_HIDE | FWF_NOICONS | FWF_HIDEFILENAMES

            self.app_data.set_icons_data(hide_snapshot,
                                         flags=pcp.ISF_EXACTLY_AFTER_FLAGS | pcp.ISF_SKIP_DEFAULT_AFTER_FLAGS,
                                         before_desktop_flags=FWF_HIDEFILENAMES,
                                         after_desktop_flags=hide_flags)

            current_time = int(time.time() * 1000)
            self.snapshots_data.append(
                SnapshotData(
                    snapshot_hash=str(current_time),
                    snapshot_name=HIDE_SHOW_HIDDEN_POINT,
                    snapshot_date=current_time,
                    desktop_flags=hide_flags,
                    icons_snapshot=hide_snapshot,
                    snapshot_locked=True
                )
            )
            self.snapshots_data.append(
                SnapshotData(
                    snapshot_hash=str(current_time),
                    snapshot_name=HIDE_SHOW_RESTORE_POINT,
                    snapshot_date=current_time,
                    desktop_flags=current_flags,
                    icons_snapshot=restore_snapshot,
                    snapshot_locked=True
                )
            )
            self.app_data.hide_show_button_active = True
        else:
            try:
                current_flags = self.app_data.get_desktop_flags()
                start_flags = current_flags & MASK_OFF_FLAGS_ON_HIDE ^ FWF_NOICONS | FWF_HIDEFILENAMES

                self.app_data.set_icons_data(restore_snapshot.icons_snapshot,
                                             flags=pcp.ISF_EXACTLY_FLAGS | pcp.ISF_SKIP_DEFAULT_AFTER_FLAGS,
                                             before_desktop_flags=start_flags,
                                             after_desktop_flags=restore_snapshot.desktop_flags)
            except Exception as E:
                print(E)

            del self.snapshots_data[-2:]
            self.app_data.hide_show_button_active = False
            created = False

        self.app_data.recalc_slots_state()
        self.trigger_save(save_app_data=False)
        return created

    def _unshift_new_snapshot(self):
        current_time = int(time.time()*1000)
        snapshot_data = SnapshotData(
            snapshot_hash=str(current_time),
            snapshot_name="Auto Snapshot",
            snapshot_date=current_time,
            desktop_flags=self.app_data.get_desktop_flags(),
            icons_snapshot=self.app_data.get_icons_data()
        )
        self.snapshots_data.insert(0, snapshot_data)
        self.app_data.new_snapshot_unshifted()
        self.trigger_save(save_app_data=False)

    def _remove_snapshot(self, snap_ind: int) -> bool:
        if snap_ind >= len(self.snapshots_data):
            return False

        removed_snap: SnapshotData = self.snapshots_data.pop(snap_ind)
        self.app_data.snapshot_was_removed(removed_snap.snapshot_hash, snap_ind)
        self.trigger_save(save_app_data=False)
        return True

    def rename_snapshot(self, snap_ind: int, value: str):
        self.snapshots_data[snap_ind].snapshot_name = value
        self.trigger_save(save_app_data=False)

    def activate_snapshot(self, snap_ind: int, *, transition=None,
                          callback_on_start: Callable = lambda: None,
                          callback_on_finish: Callable = lambda: None):
        if snap_ind < 0 or snap_ind >= len(self.snapshots_data):
            return

        assert transition is None # TODO: Replace on "Transition" release

        target_snapshot = self.snapshots_data[snap_ind]

        callback_on_start()
        self.app_data.set_icons_data(target_snapshot.icons_snapshot, after_desktop_flags=target_snapshot.desktop_flags)
        self.app_data.recalc_slots_state()
        callback_on_finish()

    def _load_app_data(self, snapshot_hashes: List[str]):
        loaded_data = {}

        if os.path.isfile(self._app_config_file):
            with open(self._app_config_file, 'r') as f:
                loaded_data = json.load(f)

        self.app_data = AppData(
            on_change_trigger=self.trigger_save,
            snapshots_data=self.snapshots_data,
            **loaded_data
        )
        self.app_data.recalc_snapshots_bindings(snapshot_hashes)
        self.app_data.recalc_slots_state()
        self.app_data.check_hide_show_button()

    def _load_snapshots_data(self):

        snapshot_hashes = []

        if os.path.isfile(self._snapshots_data_file):
            with open(self._snapshots_data_file, 'r') as f:
                loaded_data = json.load(f)

            for snap_dict in loaded_data:
                snapshot_hashes.append(snap_dict.get("snapshot_hash"))
                self.snapshots_data.append(SnapshotData(**snap_dict))

        self._load_app_data(snapshot_hashes)

    def trigger_save(self, save_snapshots_data: bool = True,
                     save_app_data: bool = True,
                     immediately: bool = False):

        if self.save_manager_timer is not None:
            self.save_manager_close_event.set()
            self.save_manager_timer.join()

        self.save_manager_close_event.clear()
        self.save_manager_timer = Thread(
            target=self._save_all_data,
            name="SaveDataManager",
            args=(save_snapshots_data, save_app_data, immediately)
        )
        self.save_manager_timer.start()

    def _save_all_data(self, save_snapshots_data: bool,
                       save_app_data: bool,
                       immediately: bool = False):
        time_begin = time.time()
        if not immediately:
            while not self.save_manager_close_event.is_set() and\
                    time_begin + self._save_interval > time.time():
                time.sleep(0.050)

        if self.save_manager_close_event.is_set():
            return

        if save_snapshots_data:
            self._save_snapshots_data()

        if save_app_data:
            self._save_app_data()

        self.save_manager_close_event.set()

    def _save_snapshots_data(self):
        with open(self._snapshots_data_file, "w") as f:
            json.dump(self.snapshots_data, f, cls=DataManagerJSONEncoder)

    def _save_app_data(self):
        with open(self._app_config_file, "w") as f:
            json.dump(self.app_data, f, cls=DataManagerJSONEncoder)
