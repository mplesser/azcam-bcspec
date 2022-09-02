"""
AzCam environment for UArizona's Bok telescope BCSpec facility CCD camera.
"""

from importlib import metadata

__version__ = metadata.version(__package__)
__version_info__ = tuple(int(i) for i in __version__.split(".") if i.isdigit())
