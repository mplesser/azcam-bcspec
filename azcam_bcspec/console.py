"""
Setup method for mont4k azcamconsole.
Usage example:
  ipython -i -m azcam_bcspc.console --profile azcamconsole
"""

import os
import sys
import threading

import azcam
import azcam.utils
import azcam_console.console
from azcam_console.tools import create_console_tools
import azcam_console.shortcuts
from azcam.tools.ds9display import Ds9Display
from azcam_console.observe.observe_cli.observe_cli import ObserveCli
import azcam_console.tools.console_tools


def setup():
    # command line arguments
    try:
        i = sys.argv.index("-datafolder")
        datafolder = sys.argv[i + 1]
    except ValueError:
        datafolder = None

    # files and folders
    azcam.db.systemname = "bcspec"
    azcam.db.systemfolder = f"{os.path.dirname(__file__)}"
    azcam.db.datafolder = azcam.utils.get_datafolder(datafolder)

    parfile = os.path.join(
        azcam.db.datafolder,
        "parameters",
        f"parameters_console_{azcam.db.systemname}.ini",
    )

    # start logging
    logfile = os.path.join(azcam.db.datafolder, "logs", "console.log")
    azcam.db.logger.start_logging(logfile=logfile)
    azcam.log(f"Configuring console for {azcam.db.systemname}")

    # display
    display = Ds9Display()
    dthread = threading.Thread(target=display.initialize, args=[])
    dthread.start()  # thread just for speed

    # console tools
    create_console_tools()

    # observe
    observe = ObserveCli()

    # try to connect to azcamserver
    server = azcam.db.tools["server"]
    connected = server.connect(port=2452)
    if connected:
        azcam.log("Connected to azcamserver")
    else:
        azcam.log("Not connected to azcamserver")

    # par file
    azcam.db.parameters.read_parfile(parfile)
    azcam.db.parameters.update_pars()


# start
setup()

from azcam_console.cli import *

del setup
