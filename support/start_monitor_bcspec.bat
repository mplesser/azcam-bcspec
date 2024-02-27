@echo off

start/min "azcammonitor" python -m azcam_server.monitor.azcammonitor -configfile "/data/azcam-bcspec/parameters/parameters_monitor_bcspec.ini"
