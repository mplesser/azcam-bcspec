"""
Setup method for bcspec azcamserver.
Usage example:
  python -i -m azcam_bcspec.server
"""

import os
import sys

import azcam
import azcam.utils
import azcam.server
import azcam.shortcuts
from azcam.cmdserver import CommandServer
from azcam.header import System
from azcam.tools.arc.controller_arc import ControllerArc
from azcam.tools.arc.exposure_arc import ExposureArc
from azcam.tools.arc.tempcon_arc import TempConArc
from azcam.tools.ds9display import Ds9Display
from azcam_bcspec.instrument_bcspec import BCSpecInstrument
from azcam_bcspec.telescope_bok import BokTCS
from azcam.webtools.webserver.fastapi_server import WebServer
from azcam.webtools.status.status import Status
from azcam.webtools.exptool.exptool import Exptool


def setup():
    # command line args
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

    # define folders for system
    azcam.db.systemname = "bcspec"
    azcam.db.servermode = azcam.db.systemname

    azcam.db.systemfolder = os.path.dirname(__file__)
    azcam.db.systemfolder = azcam.utils.fix_path(azcam.db.systemfolder)

    azcam.db.datafolder = azcam.utils.get_datafolder(datafolder)

    parfile = os.path.join(
        azcam.db.datafolder,
        "parameters",
        f"parameters_server_{azcam.db.systemname}.ini",
    )

    # enable logging
    logfile = os.path.join(azcam.db.datafolder, "logs", "server.log")
    azcam.db.logger.start_logging(logfile=logfile)
    azcam.log(f"Configuring for BCSpec")

    # controller
    controller = ControllerArc()
    controller.timing_board = "gen1"
    controller.clock_boards = ["gen1"]
    controller.video_boards = ["gen1"]
    controller.utility_board = "gen1"
    controller.set_boards()
    controller.video_gain = 1
    controller.video_speed = 1
    controller.utility_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsputility", "util1.lod"
    )
    controller.pci_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsppci", "pci1.lod"
    )
    controller.timing_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsptiming", "tim1_norm_LR.lod"
    )
    if lab:
        controller.camserver.set_server("10.0.0.3", 2405)
    else:
        controller.camserver.set_server("10.30.1.34", 2405)

    # temperature controller
    tempcon = TempConArc()
    tempcon.control_temperature = -135.0
    tempcon.set_calibrations([1, 1, 3])

    # exposure
    exposure = ExposureArc()
    exposure.filetype = exposure.filetypes["FITS"]
    exposure.image.filetype = exposure.filetypes["FITS"]
    exposure.display_image = 0
    exposure.folder = azcam.db.datafolder
    if not lab:
        exposure.send_image = 1
        exposure.sendimage.set_remote_imageserver("10.30.1.2", 6543, "dataserver")

    ref1 = 1.0
    ref2 = 1.0
    exposure.image.header.set_keyword("CRPIX1", ref1, "Coordinate reference pixel")
    exposure.image.header.set_keyword("CRPIX2", ref2, "Coordinate reference pixel")
    CD1_1 = 1.0
    CD1_2 = 0.0
    CD2_1 = 0.0
    CD2_2 = 1.0
    exposure.image.header.set_keyword("CD1_1", CD1_1, "Coordinate matrix")
    exposure.image.header.set_keyword("CD1_2", CD1_2, "Coordinate matrix")
    exposure.image.header.set_keyword("CD2_1", CD2_1, "Coordinate matrix")
    exposure.image.header.set_keyword("CD2_2", CD2_2, "Coordinate matrix")

    # detector
    detector_bcspec = {
        "name": "1200x800",
        "description": "STA 1200x800 CCD",
        "ref_pixel": [600, 400],
        "format": [1200, 18, 0, 20, 800, 0, 0, 0, 0],
        "focalplane": [1, 1, 1, 1, [0]],
        "roi": [1, 1200, 1, 800, 2, 2],
        "ext_position": [[1, 1]],
        "jpg_order": [1, 1],
        "ctype": ["LINEAR", "LINEAR"],
    }
    exposure.set_detpars(detector_bcspec)

    # instrument
    instrument = BCSpecInstrument()

    # telescope
    telescope = BokTCS()

    # system header template
    template = os.path.join(
        azcam.db.datafolder, "templates", "fits_template_bcspec_master.txt"
    )
    system = System("bcspec", template)
    system.set_keyword("DEWAR", "bcspec", "Dewar name")

    # display
    display = Ds9Display()

    # par file
    azcam.db.parameters.read_parfile(parfile)
    azcam.db.parameters.update_pars()

    # define and start command server
    cmdserver = CommandServer()
    cmdserver.port = 2442
    azcam.log(f"Starting cmdserver - listening on port {cmdserver.port}")
    # cmdserver.welcome_message = "Welcome - azcam-itl server"
    cmdserver.start()

    # web server
    webserver = WebServer()
    webserver.logcommands = 0
    webserver.index = os.path.join(azcam.db.systemfolder, "index_bcspec.html")
    webserver.port = 2403  # common port for all configurations
    webserver.start()
    webstatus = Status(webserver)
    webstatus.initialize()

    # GUI
    if 1:
        import azcam_bcspec.start_azcamtool

    # finish
    azcam.log("Configuration complete")


# start
setup()
from azcam.cli import *
