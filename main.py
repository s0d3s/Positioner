if __name__ == "__main__":
    import os
    import sys

    from argparse import ArgumentParser

    sys.path.insert(1, os.path.abspath("./src"))

    from src.positioner import run_gui
    from src.qml_connections.utils_model import UtilsModel

    arg_parse = ArgumentParser()
    arg_parse.add_argument("--exit", default=False, action="store_true",
                           help="Do not run GUI, only execute actions passed via cmd arguments")
    arg_parse.add_argument("--min", default=False, action="store_true",
                           help="Start in minimized mode")
    arg_parse.add_argument("--restore-slot", "-r", type=int, metavar="INDEX", default=-2,
                           help="Restore snapshot from slot with <INDEX>")
    arg_parse.add_argument("--restore-transition", "-rt", metavar="TRANS",
                           help="Use transition <TRANS> when restoring snapshot")
    arg_parse.add_argument("--save-slot", "-s", type=int, metavar="INDEX", default=-2,
                           help="Create new snapshot and save it to slot with <INDEX>")
    arg_parse.add_argument("--delete-autorun", default=False, action="store_true", help="Delete autorun from winreg")

    actions = arg_parse.parse_args()
    utils_model = UtilsModel()

    if 3 > actions.restore_slot > -1:
        transition = None # actions.restore_transition # Create Transition object # TODO: Replace on "Transition" release
        utils_model.activate_from_slot(actions.restore_slot, transition=transition)

    if 3 > actions.save_slot > -1:
        # create new snapshot and attach to slot
        utils_model.create_snapshot_and_attach_to(actions.save_slot)

    if actions.delete_autorun:
        utils_model.delete_from_autorun()

    if not actions.exit:

        try:
            #Added by cx_Freeze
            import BUILD_CONSTANTS

            from contextlib import redirect_stdout, redirect_stderr
            from datetime import datetime

            SCRIPT_DIR = os.path.dirname(os.path.abspath(sys.executable))
            LOGS_DIR = os.path.join(SCRIPT_DIR, "logs")

            os.makedirs(LOGS_DIR, exist_ok=True)

            # redirect output to file

            with open(
                os.path.join(
                    LOGS_DIR,
                    f"log_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.txt"
                ), "a"
            ) as log_f:
                with redirect_stdout(log_f), redirect_stderr(log_f):
                    run_gui(actions.min)

        except ImportError:
            run_gui(actions.min)

    else:
        utils_model._data_man.prepare_exit()
