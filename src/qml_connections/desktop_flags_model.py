from typing import Any, Dict, Sequence, List

from PySide6.QtCore import QAbstractListModel, QByteArray, QModelIndex, Qt, Slot

try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    from ..data_manager import DataManager

except ImportError:
    from src.data_manager import DataManager

# https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
FOLDER_FLAGS: Sequence[Dict[str, Any]] = [
    {"flag": 0x1,       "name": "FWF_AUTOARRANGE",
                        "title": "Auto Arrange",
                        "description": "Automatically arrange the icons"},
    #{"flag": 0x2,       "name": "FWF_ABBREVIATEDNAMES", "title": "2", "description": ""},
    {"flag": 0x4,       "name": "FWF_SNAPTOGRID",
                        "title": "Snap to grid",
                        "description": "Snap icon positions to grid"},
    #{"flag": 0x8,       "name": "FWF_OWNERDATA", "title": "4", "description": ""},
    #{"flag": 0x10,      "name": "FWF_BESTFITWINDOW", "title": "5", "description": ""},
    #{"flag": 0x20,      "name": "FWF_DESKTOP", "title": "6", "description": ""},
    {"flag": 0x40,      "name": "FWF_SINGLESEL",
                        "title": "Single Select",
                        "description": "Prevents selection of multiple icons"},
    #{"flag": 0x80,      "name": "FWF_NOSUBFOLDERS", "title": "8", "description": ""},
    #{"flag": 0x100,     "name": "FWF_TRANSPARENT", "title": "9", "description": ""},
    #{"flag": 0x200,     "name": "FWF_NOCLIENTEDGE", "title": "10", "description": ""},
    #{"flag": 0x400,     "name": "FWF_NOSCROLL", "title": "11", "description": ""},
    #{"flag": 0x800,     "name": "FWF_ALIGNLEFT", "title": "12", "description": ""},
    {"flag": 0x1000,    "name": "FWF_NOICONS",
                        "title": "Hide Icons", "description": "Don't show icons"},
    #"flag": 0x2000,    "name": "FWF_SHOWSELALWAYS", "title": "14", "description": ""},
    #{"flag": 0x4000,    "name": "FWF_NOVISIBLE", "title": "15", "description": ""},
    {"flag": 0x8000,    "name": "FWF_SINGLECLICKACTIVATE",
                        "title": "One Click Activate",
                        "description": "Icons open with one click"},
    #{"flag": 0x10000,   "name": "FWF_NOWEBVIEW", "title": "17", "description": ""},
    {"flag": 0x20000,   "name": "FWF_HIDEFILENAMES",
                        "title": "Hide Filenames",
                        "description": "Don't show filenames"},
    {"flag": 0x40000,   "name": "FWF_CHECKSELECT",
                        "title": "Checkbox Select #0",
                        "description": "Rudiment. Check for fun"},
    #{"flag": 0x80000,   "name": "FWF_NOENUMREFRESH", "title": "20", "description": ""},
    #{"flag": 0x100000,  "name": "FWF_NOGROUPING", "title": "21", "description": ""},
    #{"flag": 0x200000,  "name": "FWF_FULLROWSELECT", "title": "22", "description": ""},
    #{"flag": 0x400000,  "name": "FWF_NOFILTERS", "title": "23", "description": ""},
    #{"flag": 0x800000,  "name": "FWF_NOCOLUMNHEADER", "title": "24", "description": ""},
    #{"flag": 0x1000000, "name": "FWF_NOHEADERINALLVIEWS", "title": "25", "description": ""},
    #{"flag": 0x2000000, "name": "FWF_EXTENDEDTILES", "title": "26", "description": ""},
    {"flag": 0x4000000, "name": "FWF_TRICHECKSELECT",
                        "title": "Checkbox Select #1",
                        "description": "Rudiment. Check for fun"},
    {"flag": 0x8000000, "name": "FWF_AUTOCHECKSELECT",
                        "title": "Checkbox Select #2",
                        "description": "Rudiment. Check for fun"},
]


class DesktopFlagsModel(QAbstractListModel):

    FlagName = Qt.UserRole + 1
    FlagTitle = Qt.UserRole + 2
    FlagDescription = Qt.UserRole + 3
    FlagIsActive = Qt.UserRole + 4

    def __init__(self, parent=None) -> None:
        super().__init__(parent=parent)
        self._data = DataManager()

        self.desktop_flags: List[Dict[str, Any]] = []
        self.updateFlags()

    def rowCount(self, parent=QModelIndex()):
        return len(self.desktop_flags)

    def roleNames(self):
        default = super().roleNames()
        default[self.FlagName] = QByteArray(b"name")
        default[self.FlagTitle] = QByteArray(b"title")
        default[self.FlagDescription] = QByteArray(b"description")
        default[self.FlagIsActive] = QByteArray(b"isActive")
        return default

    def data(self, index, role: int):
        if not index.isValid():
            ret = None
        elif role == self.FlagName:
            ret = self.desktop_flags[index.row()]["name"]
        elif role == self.FlagTitle:
            ret = self.desktop_flags[index.row()]["title"]
        elif role == self.FlagDescription:
            ret = self.desktop_flags[index.row()]["description"]
        elif role == self.FlagIsActive:
            ret = self.desktop_flags[index.row()]["isActive"]
        else:
            ret = None
        return ret

    @Slot()
    def updateFlags(self):
        current_flags = self._data.app_data.get_desktop_flags()

        self.beginResetModel()
        self.desktop_flags = [
            {
                "flag": flag["flag"],
                "name": flag["name"],
                "title": flag["title"],
                "description": flag["description"],
                "isActive": bool(flag["flag"] & current_flags),
            }
            for flag in FOLDER_FLAGS
        ]
        self.endResetModel()

    @Slot(int)
    def toggleFlag(self, flag_index: int):
        self._data.app_data.switch_desktop_flags(self.desktop_flags[flag_index]["flag"])
        self.desktop_flags[flag_index]["isActive"] = not self.desktop_flags[flag_index]["isActive"]
