import subprocess
import version

NECESSARY_ARGS = {
    "PositionerAppName": version.app_target_name,
    "PositionerVersion": version.version,
    "PositionerAuthor": version.author,
    "PositionerAppURL": version.home_page,
    "PositionerExeName": f"{version.exe_target_name}.exe",
    "PositionerInstallerName": "positioner_installer",
    "PositionerOutputDir": "installer_build",
}

NECESSARY_ARGS_HELP = "Necessary args: "\
                      + " ".join(f"{arg_name}=[{arg_value}]"
                                  for arg_name, arg_value in NECESSARY_ARGS.items())


def build_inno_args(**kwargs):
    for n_arg in NECESSARY_ARGS.keys():
        if n_arg not in kwargs:
            kwargs[n_arg] = NECESSARY_ARGS[n_arg]
    
    # print("Compiling args:\n"
    #       + "\n".join(f" - {arg_name}={arg_value}" for arg_name, arg_value in kwargs.items()))
          
    return kwargs


def compile_installer(inno_def_args: dict, run_inno_command, inno_config="inno_compile.iss"):
    add_arguments = " ".join(f"\"/D{arg_name}={arg_value}\"" for arg_name, arg_value in inno_def_args.items())

    run_command = f"{run_inno_command} {add_arguments} {inno_config}"

    print("\n+++++ Compile via command:\n" +
          f"> {run_command}\n")

    subprocess.run(run_command)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--inno", default="iscc")
    parser.add_argument("--override", "-o", metavar="ARG=VALUE", nargs="+", help=NECESSARY_ARGS_HELP)
    args = parser.parse_args()

    override_args = {}
    if args.override:
        for o_a in args.override:
            arg_name, arg_value = o_a.split("=")
            override_args[arg_name] = arg_value

    inno_def_args = build_inno_args(**override_args)
    compile_installer(inno_def_args, args.inno)
