"""
azcam server script for ITL systems.

Usage: python -m azcam_itl.server
"""

import azcam_bcspec.server_bcspec

# CLI commands - -m command line flags brings these into CLI namespace
from azcam.cli import *
