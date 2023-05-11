""" Mappings for `version` file """
import json
import sys
import os


try:
    #Added by cx_Freeze
    import BUILD_CONSTANTS
    ENTRY_POINT_DIR = os.path.dirname(os.path.abspath(sys.executable))

except ImportError:
    ENTRY_POINT_DIR = os.path.dirname(os.path.abspath(__file__))


version_file = os.path.join(ENTRY_POINT_DIR, "version.json")

app_target_name: str = "Positioner"
exe_target_name: str = app_target_name

version: str = "0.0.0"
author: str = "S0D3S"
home_page: str = "..."

with open(version_file, 'r', encoding="utf-8") as f:
    globals().update(json.load(f))

if __name__ == '__main__':
    print(globals())
