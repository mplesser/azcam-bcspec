# =======================================================================================
#
# Modified from "https://gist.github.com/dgerod/549273a7bf5114d008b6.js">
#
# ---------------------------------------------------------------------------------------
# This is a modification of the code done by Gaute Hope <gaute.hope@nersc.no> due to
# IPython issue 101
#
# References:
#   - https://github.com/ipython/ipython/issues/101
#   - http://ipython.org/ipython-doc/dev/config/custommagics.html
#   - https://gist.github.com/gauteh/2f8f49f082f1d09b3db0
# =======================================================================================

import os, sys
from IPython import get_ipython
from IPython.core.magic import register_line_magic
from IPython.utils.path import filefind

_my_custom_paths = []


def find_in_pythonpath(filename):
    global _my_custom_paths

    _my_custom_paths = sys.path

    try:
        path_dirs = ["."] + _my_custom_paths + os.environ["PYTHONPATH"].split(":")
    except:
        path_dirs = ["."] + _my_custom_paths

    return filefind(filename, path_dirs)


def find_in_syspath(filename):
    return filefind(filename, sys.path)


@register_line_magic
def Run(line):
    tokens = line.split(" ")
    cmd = tokens[0]
    if cmd.endswith(".py"):
        pass
    else:
        if len(tokens) == 1:
            line = f"{cmd}.py"
        else:
            line = f"{cmd}.py {' '.join(tokens[1:])}"

    ip = get_ipython()
    ip.magics_manager.magics["line"]["run"](line, file_finder=find_in_pythonpath)


del Run


@register_line_magic
def add_custom_path(line):
    global _my_custom_paths
    if os.path.isabs(line) == False:
        path = os.path.abspath(line)
    else:
        path = line
    if path not in _my_custom_paths:
        _my_custom_paths.append(path)


del add_custom_path


@register_line_magic
def clean_custom_path(line):
    global _my_custom_paths
    _my_custom_paths = []


del clean_custom_path


@register_line_magic
def show_custom_path(line):
    global _my_custom_paths
    for path in _my_custom_paths:
        print(path)


del show_custom_path

"""
# Run command
f1 = open(os.devnull, "w")  # disable annoying prints
f2 = sys.stdout
sys.stdout = f1
ip.magic("alias_magic -p '-i' Run my_run")
sys.stdout = f2
"""
