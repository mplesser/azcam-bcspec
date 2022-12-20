# azcam-bcspec

## Purpose

This repository contains the *azcam-bcspec* azcam environment.  It contains code and data files for the University of Arizona Bok telescope B&C Spectrograph facility camera system.

## Installation

Download the code (usually into the *azcam* root folder such as `c:\azcam`) and install.

```shell
cd /azcam
git clone https://github.com/mplesser/azcam-bcspec
cd azcam-bcspec
pip install -e .
```

# Notes

## System Setup
- install Windows 10 and do updates

### Install python
- Download and install VS Code with GIT (notpad as editor)
- install python to c:\python3x (e.g. c:\python39)

### Install azcam
- create and cd to c:\azcam
- git clone https://github.com/mplesser/azcam-bcspec
- git clone https://github.com/mplesser/azcam-tool
- git clone https://github.com/mplesser/azcam-ds9-winsupport

- [copy or] git clone https://github.com/mplesser/motoroladsptools

- pip install -e .\azcam-bcspec

- install Labview 2014 runtime for azcam-tool
- install SAO ds9
- install and start xpans and nssm from azcam-ds9-winsupport

### If PC is a controller server
- install ARC Win10 PCI card driver
- install and configure controller server

### update powershell
- winget install --id=Microsoft.PowerShell -e

