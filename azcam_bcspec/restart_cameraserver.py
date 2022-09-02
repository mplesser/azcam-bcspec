"""
restart_cameraserver

This is just a fix for PC hang issue...
09Oct19 MPL
"""

import os

filepath = "C:\\azcam\\camera_servers\\installer64_19.3\\RestartServiceAdmin.bat.lnk"

print("Restarting cameraserver")
os.system(filepath)
