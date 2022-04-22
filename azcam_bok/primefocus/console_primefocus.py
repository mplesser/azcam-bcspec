# azcamconsole config file

import os
import sys
import threading

import azcam
import azcam.console
import azcam.shortcuts
import azcam.tools.console_tools
from azcam_ds9.ds9display import Ds9Display
from azcam_focus.focus import Focus
from azcam_observe.observe import Observe

try:
    i = sys.argv.index("-datafolder")
    datafolder = sys.argv[i + 1]
except ValueError:
    datafolder = None
try:
    i = sys.argv.index("-lab")
    lab = 1
except ValueError:
    lab = 0

# ****************************************************************
# files and folders
# ****************************************************************
azcam.db.systemname = "90prime"

azcam.db.systemfolder = f"{os.path.dirname(__file__)}"

if datafolder is None:
    droot = os.environ.get("AZCAM_DATAROOT")
    if droot is None:
        droot = "/data"
    azcam.db.datafolder = os.path.join(droot, azcam.db.systemname)
else:
    azcam.db.datafolder = datafolder
azcam.db.datafolder = azcam.utils.fix_path(azcam.db.datafolder)

parfile = os.path.join(
    azcam.db.datafolder, f"parameters_{azcam.db.systemname}_console.ini"
)

# ****************************************************************
# start logging
# ****************************************************************
logfile = os.path.join(azcam.db.datafolder, "logs", "console.log")
azcam.db.logger.start_logging(logfile=logfile)
azcam.log(f"Configuring console for {azcam.db.systemname}")

# ****************************************************************
# display
# ****************************************************************
display = Ds9Display()
dthread = threading.Thread(target=display.initialize, args=[])
dthread.start()  # thread just for speed

# ****************************************************************
# console tools
# ****************************************************************
from azcam.tools import create_console_tools

create_console_tools()

# ****************************************************************
# observe script
# ****************************************************************
observe = Observe()
observe.move_telescope_during_readout = 1

# ****************************************************************
# focus script
# ****************************************************************
focus = Focus()
focus.focus_component = "instrument"
focus.focus_type = "step"

# ****************************************************************
# try to connect to azcamserver
# ****************************************************************
ports = [2402, 2412, 2422, 2432]
connected = 0
server = azcam.db.tools["server"]
for port in ports:
    connected = server.connect(port=port)
    if connected:
        break

if connected:
    azcam.log("Connected to azcamserver")
else:
    azcam.log("Not connected to azcamserver")

# ****************************************************************
# parameter file
# ****************************************************************
azcam.db.tools["parameters"].read_parfile(parfile)
azcam.db.tools["parameters"].update_pars(0, "azcamconsole")
