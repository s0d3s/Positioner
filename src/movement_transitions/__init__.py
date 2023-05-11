from typing import List
from types import ModuleType
from glob import glob

import os
import importlib


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def collect_available_transitions(positioner_c_part: ModuleType) -> List['TransitionHandler']:
    transitions_list = []
    for file_path in glob(os.path.join(SCRIPT_DIR, "*.py")):
        if file_path.endswith(__file__):
            continue

        transition_file = f"movement_transitions.{os.path.basename(file_path).rsplit('.', 1)[0]}"

        try:
            t_mod = importlib.import_module(transition_file)
            transitions_list.append(
                t_mod.construct_transition_object(positioner_c_part.TransitionHadler, positioner_c_part)
            )
        except (ModuleNotFoundError, AttributeError) as E:
            continue

    return transitions_list
