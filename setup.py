from cx_Freeze import setup, Executable
from setuptools import Extension

import os
import sys
import time
import version

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_LIB_DIR = os.path.join(SCRIPT_DIR, 'build_pcp')

sys.path.append(BUILD_LIB_DIR)


build_options = {'build_lib': BUILD_LIB_DIR}
build_ext_options = {
    'build_exe': 'build/exe',
    'includes': ['positioner_c_part'],
    'excludes': [
        'src.positioner_ui', 'src.c_part', 'src.movement_transitions',
        'PySide6.examples', 'PySide6.include', 'PySide6.glue', 'PySide6.resources',
        'PySide6.scripts', 'PySide6.support', 'PySide6.translations', 'PySide6.typesystems',
        'PySide6.qml.QtQuick3D', 'PySide6.qml.Qt3D'#, 'PySide6.', 'PySide6.',
    ],
    'bin_excludes': [
        'Qt6WebEngineCore.dll', 'Qt6WebEngineWidgets.dll', 'lupdate.exe', 'Qt6Charts.dll', 'assistant.exe',
        'Qt3DRender.pyd', 'Qt6DataVisualization.dll', 'Qt6LanguageServer.dll', 'linguist.exe',
        'Qt6Quick3D.dll', 'Qt6Bluetooth.dll', 'designer.exe', 'opengl32sw.dll', 'QtOpenGL.pyd',
        'Qt6Designer.dll', 'Qt6Pdf.dll', 'd3dcompiler_47.dll', 'Qt63DRender.dll', 'Qt6DesignerComponents.dll',
        'Qt6Quick3DRuntimeRender.dll', 'Qt6ShaderTools.dll',
    ],
    'include_files': [
        ('version.json', 'version.json'),
        ('src/positioner_ui', 'lib/src/positioner_ui'),
        ('src/movement_transitions', 'src/movement_transitions'),
    ],
    'constants': [f'BUILD_TIMESTAMP={int(time.time())}', f'VERSION="{version.version}"']
}


base = 'Win32GUI' if sys.platform=='win32' else None # 'console'

executables = [
    Executable(
        'main.py',
        base=base,
        target_name=version.exe_target_name,
        icon='src/positioner_ui/assets/favicon_positioner.ico'
    )
]

positioner_c_part_ext = Extension(
    name='positioner_c_part',
    sources=['./src/c_part/positioner_c_part/positioner_c_part.cpp']
)

setup(
    name=version.exe_target_name,
    version=version.version,
    description='Manage Desktop icons position[Windows only]',
    options={'build_exe': build_ext_options, 'build': build_options},
    ext_modules=[
        positioner_c_part_ext
    ],
    executables=executables
)
