from typing import Type, Tuple
from types import ModuleType


def construct_transition_object(
        base_transition_class: Type['TransitionHandler'],
        positioner_c_part: ModuleType) -> 'TransitionHandler':
    class DefaultTransition(base_transition_class):

        """
        name: str
        description: str
        allotted_time: int

        steps_count: int
        data: Dict[Any, Any]
        """

        def __init__(self, transition_name: str, allotted_time: int):
            super().__init__(name=transition_name, allotted_time=allotted_time)
            self.description = "Easy-out transition"

        def handle_init(self, icons_data):
            super().handle_init(icons_data)

        def handle_position(self,              icon_pidl: str,
                            call_flag: int,    iteration_num: int,
                            elapsed_time: int, allotted_time: int,
                            origin_x: int,     origin_y: int,
                            current_x: int,    current_y: int,
                            target_x: int,     target_y: int) -> Tuple[int, int, int]:

            return super().handle_position(icon_pidl, call_flag,
                                           iteration_num,
                                           elapsed_time, allotted_time,
                                           origin_x, origin_y,
                                           current_x, current_y,
                                           target_x, target_y)

        def handle_between_iter(self, elapsed_time: int, allotted_time: int):
            super().handle_between_iter(elapsed_time, allotted_time)

        def handle_final(self):
            super().handle_final()

    return DefaultTransition("Default", 1000000)
