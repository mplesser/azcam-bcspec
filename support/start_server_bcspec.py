"""
Python process start file
"""

import subprocess

OPTIONS = "-bcspec"
# OPTIONS = "-bcspec -lab"
CMD = f"ipython --profile azcamserver -i -m azcam_90prime.server -- {OPTIONS}"

p = subprocess.Popen(
    CMD,
    creationflags=subprocess.CREATE_NEW_CONSOLE,
)
