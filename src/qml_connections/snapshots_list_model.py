from typing import Any, Dict, Callable
from datetime import datetime
import time

from PySide6.QtCore import QAbstractListModel, QByteArray, QModelIndex, Qt, Slot, Signal, Property

try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    from ..data_manager import DataManager

except ImportError:
    from src.data_manager import DataManager


def _set_iats_qml_prop(slot_ind: int) -> Callable:
    def set_wrap(self, value: Any) -> None:
        self.setIndexAttachedToVar(slot_ind, value)

    return set_wrap


def _get_iats_qml_prop(slot_ind: int) -> Callable:
    def get_wrap(self) -> Any:
        return self._data.app_data.get_slot_binding(slot_ind)

    return get_wrap


def _get_set_for_index_attached_to_slot_qml_prop(slot_ind: int) -> Dict[str, Any]:
    return {
        "fget": _get_iats_qml_prop(slot_ind),
        "fset": _set_iats_qml_prop(slot_ind)
    }


def _set_isa_qml_prop(slot_ind: int) -> Callable:
    def set_wrap(self, value: Any) -> None:
        self.updateSlotsState()

    return set_wrap


def _get_isa_qml_prop(slot_ind: int) -> Callable:
    def get_wrap(self) -> Any:
        return self._data.app_data.get_slot_state(slot_ind)

    return get_wrap


def _get_set_for_is_slot_active_qml_prop(slot_ind: int) -> Dict[str, Any]:
    return {
        "fget": _get_isa_qml_prop(slot_ind),
        "fset": _set_isa_qml_prop(slot_ind)
    }


class SnapshotsListModel(QAbstractListModel):
    """
    TODO: Remove hardcoded `slots`
    """
    _selectedSnapshotIndexChanged = Signal(int)
    _enableSlotControlsChanged = Signal(bool)
    _hideShowIsActiveChanged = Signal()

    _indexAttachedToFirstSlotChanged = Signal()
    _indexAttachedToSecondSlotChanged = Signal()
    _indexAttachedToThirdSlotChanged = Signal()

    _isFirstSlotActiveChanged = Signal()
    _isSecondSlotActiveChanged = Signal()
    _isThirdSlotActiveChanged = Signal()

    _countChanged = Signal()

    selectedSnapshotIndex = Property(
        int,
        fget=lambda self: getattr(self, "_selectedSnapshotIndex"),
        fset=lambda self, value, prop_name="_selectedSnapshotIndex":
            (lambda _: getattr(
                    self,
                    f"{prop_name}Changed"
                ).emit(value))(setattr(self, prop_name, value)),
        notify=_selectedSnapshotIndexChanged
    )
    hideShowIsActive = Property(
        bool,
        fget=lambda self: self._data.app_data.get_hide_show_button_active(),
        fset=lambda self, value: None,
        notify=_hideShowIsActiveChanged
    )
    enableSlotControls = Property(
        int,
        fget=lambda self: getattr(self, "_enableSlotControls"),
        fset=lambda self, value, prop_name="_enableSlotControls":
            (lambda _: getattr(
                    self,
                    f"{prop_name}Changed"
                ).emit(value))(setattr(self, prop_name, value)),
        notify=_enableSlotControlsChanged
    )
    indexAttachedToFirstSlot = Property(
        int,
        **_get_set_for_index_attached_to_slot_qml_prop(0),
        notify=_indexAttachedToFirstSlotChanged
    )
    indexAttachedToSecondSlot = Property(
        int,
        **_get_set_for_index_attached_to_slot_qml_prop(1),
        notify=_indexAttachedToSecondSlotChanged
    )
    indexAttachedToThirdSlot = Property(
        int,
        **_get_set_for_index_attached_to_slot_qml_prop(2),
        notify=_indexAttachedToThirdSlotChanged
    )

    isFirstSlotActive = Property(
        int,
        **_get_set_for_is_slot_active_qml_prop(0),
        notify=_isFirstSlotActiveChanged
    )
    isSecondSlotActive = Property(
        int,
        **_get_set_for_is_slot_active_qml_prop(1),
        notify=_isSecondSlotActiveChanged
    )
    isThirdSlotActive = Property(
        int,
        **_get_set_for_is_slot_active_qml_prop(2),
        notify=_isThirdSlotActiveChanged
    )
    count = Property(
        int,
        fget=lambda self: self.rowCount(),
        notify=_countChanged
    )

    CaptureDate = Qt.UserRole + 1
    SnapshotName = Qt.UserRole + 2
    SnapshotLocked = Qt.UserRole + 3

    lastSlotsStateUpdate = 0
    lastSlotsStateUpdateInterval = 2.5

    available_slots = (
        "_indexAttachedToFirstSlot",
        "_indexAttachedToSecondSlot",
        "_indexAttachedToThirdSlot"
    )
    available_slots_states = (
        "_isFirstSlotActive",
        "_isSecondSlotActive",
        "_isThirdSlotActive"
    )

    def __init__(self, parent=None) -> None:
        super().__init__(parent=parent)
        self._data = DataManager()

        self._selectedSnapshotIndex = -1
        self._enableSlotControls = True

    @Slot()
    def hideShowButtonClicked(self):
        self.enableSlotControls = False
        row_count = self.rowCount()
        if self._data.hide_show_button_clicked():
            # Inserted new snapshots
            self.beginInsertRows(QModelIndex(), row_count, row_count + 1)
            self.endInsertRows()
        else:
            # Deleted old snapshots
            self.beginRemoveRows(QModelIndex(), row_count-2, row_count)
            self.endRemoveRows()

        self._hideShowIsActiveChanged.emit()
        self.enableSlotControls = True

    def _emitSlotsStateChange(self):
        for prop_name in self.available_slots_states:
            getattr(self, f"{prop_name}Changed").emit()

    def setIndexAttachedToVar(self, slot_ind: int, value: int):
        self._data.app_data.set_slot_binding(slot_ind, value)
        getattr(self, f"{self.available_slots[slot_ind]}Changed").emit()

    @Slot(int)
    def attachSelectedToSlot(self, slot_num):
        if self._selectedSnapshotIndex < 0:
            return
        self._data.app_data.attach_snap_to_slot(slot_num, self._selectedSnapshotIndex)

        for slot_name in self.available_slots:
            getattr(self, f"{slot_name}Changed").emit()

    def rowCount(self, parent=QModelIndex()):
        return len(self._data.snapshots_data)

    def roleNames(self):
        default = super().roleNames()
        default[self.CaptureDate] = QByteArray(b"snapshotDate")
        default[self.SnapshotName] = QByteArray(b"snapshotName")
        default[self.SnapshotLocked] = QByteArray(b"snapshotLocked")
        return default

    def data(self, index, role: int):
        if not index.isValid():
            ret = None
        elif role == self.SnapshotName:
            ret = self._data.snapshots_data[index.row()].snapshot_name
        elif role == self.CaptureDate:
            ret = datetime.fromtimestamp(
                self._data.snapshots_data[index.row()].snapshot_date/1000
            ).strftime('%Y-%m-%d %H:%M:%S')
        elif role == self.SnapshotLocked:
            ret = self._data.snapshots_data[index.row()].snapshot_locked
        else:
            ret = None
        return ret

    @Slot()
    def updateSlotsState(self):

        if self.lastSlotsStateUpdate + self.lastSlotsStateUpdateInterval >\
                time.time():
            return

        self.enableSlotControls = False
        self._data.app_data.recalc_slots_state()

        # re-draw all
        self._emitSlotsStateChange()
        self.lastSlotsStateUpdate = time.time()
        self.enableSlotControls = True

    @Slot()
    def activateCurrentSnapshot(self):
        self.activateSnapshot(self._selectedSnapshotIndex)

    @Slot(int)
    def activateSnapshot(self, snap_ind: int):
        self._data.activate_snapshot(
            snap_ind,
            callback_on_finish=self._emitSlotsStateChange
        )

    @Slot(int)
    def restoreSnapshotFromSlot(self, slot_ind: int):
        self.activateSnapshot(self._data.app_data.get_slot_binding(slot_ind))

    @Slot(int)
    def createSnapshotAndAttachTo(self, slot_ind: int):
        self.unshiftNew()
        self.attachSelectedToSlot(slot_ind)
        self._data.app_data.recalc_slots_state()
        self._emitSlotsStateChange()

    @Slot(int, str)
    def setSnapshotName(self, index: int, value: str):
        self._data.rename_snapshot(index, value)

    @Slot(result=bool)
    def unshiftNew(self):
        self.beginInsertRows(QModelIndex(), 0, 0)
        self._data._unshift_new_snapshot()
        self.endInsertRows()

        self.selectedSnapshotIndex = 0
        self._countChanged.emit()
        return True

    @Slot(int, result=bool)
    def remove(self, row: int):
        """Slot to remove one row"""
        self.selectedSnapshotIndex = -1
        self.beginRemoveRows(QModelIndex(), row, row)
        res = self._data._remove_snapshot(row)
        self.endRemoveRows()
        self._countChanged.emit()
        return res
