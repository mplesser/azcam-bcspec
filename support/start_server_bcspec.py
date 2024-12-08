"""
Python process start file
"""

import subprocess

OPTIONS = "-bcspec"
# OPTIONS = "-bcspec -lab"
CMD = f"ipython --ipython-dir=/data/ipython --profile azcamserver -i -m azcam_bcspec.server -- {OPTIONS}"

p = subprocess.Popen(
    CMD,
    creationflags=subprocess.CREATE_NEW_CONSOLE,
)
