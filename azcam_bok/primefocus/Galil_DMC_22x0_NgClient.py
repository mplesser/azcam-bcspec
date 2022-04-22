#!/usr/bin/env python3
# -*- coding: utf-8 -*-


# +
# import(s)
# -
from astropy.time import Time
from datetime import datetime
from datetime import timedelta

import argparse
import math
import os
import random
import socket


# +
# __doc__
# -
__doc__ = """ python3 Galil_DMC_22x0_NgClient.py --help """


# +
# constant(s)
# -
BOK_NG_HELP = os.path.abspath(
    os.path.expanduser(
        os.path.join(os.getenv("BOK_GALIL_DOCS", os.getcwd()), "bok_ng_commands.txt")
    )
)
BOK_NG_FALSE = [0, "0", "false", False]
BOK_NG_GFILTER_SLOTS = [1, 2, 3, 4, 5, 6]
BOK_NG_HOST = "10.30.1.2"
BOK_NG_IFILTER_SLOTS = [0, 1, 2, 3, 4, 5]
BOK_NG_INSTRUMENT = "90PRIME"
BOK_NG_PORT = 5750
BOK_NG_STRING = 1024
BOK_NG_TELESCOPE = "BOK"
BOK_NG_TIMEOUT = 60.0
BOK_NG_TRUE = [1, "1", "true", True]
BOK_COLORS = ["black", "blue", "cyan", "green", "yellow", "magenta", "red"]


# +
# initialize
# -
random.seed(os.getpid())


# +
# function: pdh()
# -
def pdh(msg: str = "", color: str = BOK_COLORS[0], height: int = 1):
    """print double (or single) height and in color"""

    # check input(s)
    color = color.lower() if color.lower() in BOK_COLORS else BOK_COLORS[0].lower()
    height = height if (1 <= height <= 2) else 1

    # output
    if msg != "":
        # single height
        if height == 1:
            if color == "red":
                print(f"\033[0;31m{msg}\033[0m")
            elif color == "green":
                print(f"\033[0;32m{msg}\033[0m")
            elif color == "yellow":
                print(f"\033[0;33m{msg}\033[0m")
            elif color == "blue":
                print(f"\033[0;34m{msg}\033[0m")
            elif color == "magenta":
                print(f"\033[0;35m{msg}\033[0m")
            elif color == "cyan":
                print(f"\033[0;36m{msg}\033[0m")
            else:
                print(f"\033[0;30m{msg}\033[0m")
        # double height
        elif height == 2:
            if color == "red":
                print(f"\033[0;31m\033#3{msg}\n\033#4{msg}\033[0m")
            elif color == "green":
                print(f"\033[0;32m\033#3{msg}\n\033#4{msg}\033[0m")
            elif color == "yellow":
                print(f"\033[0;33m\033#3{msg}\n\033#4{msg}\033[0m")
            elif color == "blue":
                print(f"\033[0;34m\033#3{msg}\n\033#4{msg}\033[0m")
            elif color == "magenta":
                print(f"\033[0;35m\033#3{msg}\n\033#4{msg}\033[0m")
            elif color == "cyan":
                print(f"\033[0;36m\033#3{msg}\n\033#4{msg}\033[0m")
            else:
                print(f"\033#3{msg}\n\033#4{msg}")


# +
# function: get_utc()
# -
def get_utc(_days: int = 0) -> str:
    return (datetime.utcnow() + timedelta(days=_days)).isoformat()


# +
# function: get_jd()
# -
def get_jd(_days: int = 0) -> str:
    return Time(get_utc(_days=_days)).jd


# +
# class: NgClient()
# -
# noinspection PyBroadException
class NgClient(object):

    # +
    # method: __init__()
    # -
    def __init__(
        self,
        host: str = BOK_NG_HOST,
        port: int = BOK_NG_PORT,
        timeout: float = BOK_NG_TIMEOUT,
        simulate: bool = False,
        verbose: bool = False,
    ) -> None:

        # get input(s)
        self.host = host
        self.port = port
        self.timeout = timeout
        self.simulate = simulate
        self.verbose = verbose

        # set variable(s)
        self.__answer = f""
        self.__command = f""
        self.__encoder_a = math.nan
        self.__encoder_b = math.nan
        self.__encoder_c = math.nan
        self.__error = f""
        self.__gfilters = {}
        self.__gfilters_names = []
        self.__gfilters_numbers = []
        self.__gfilters_slots = []
        self.__gfilter_name = f""
        self.__gfilter_number = -1
        self.__gfilter_rotating = False
        self.__gdelta = math.nan
        self.__gfocus = math.nan
        self.__ifilters = {}
        self.__ifilters_names = []
        self.__ifilters_numbers = []
        self.__ifilters_slots = []
        self.__ifilter_inbeam = False
        self.__ifilter_name = f""
        self.__ifilter_number = -1
        self.__ifilter_rotating = False
        self.__ifilter_translating = False
        self.__ifocus_a = math.nan
        self.__ifocus_b = math.nan
        self.__ifocus_c = math.nan
        self.__ifocus_mean = math.nan
        self.__sock = None

    # +
    # property(s)
    # -
    @property
    def host(self):
        return self.__host

    @host.setter
    def host(self, host: str = BOK_NG_HOST) -> None:
        self.__host = host if host.strip() != "" else BOK_NG_HOST

    @property
    def port(self):
        return self.__port

    @port.setter
    def port(self, port: int = BOK_NG_PORT) -> None:
        self.__port = port if port > 0 else BOK_NG_PORT

    @property
    def timeout(self):
        return self.__timeout

    @timeout.setter
    def timeout(self, timeout: float = BOK_NG_PORT) -> None:
        self.__timeout = timeout if timeout > 0.0 else BOK_NG_TIMEOUT

    @property
    def simulate(self):
        return self.__simulate

    @simulate.setter
    def simulate(self, simulate: bool = False) -> None:
        self.__simulate = simulate

    @property
    def verbose(self):
        return self.__verbose

    @verbose.setter
    def verbose(self, verbose: bool = False) -> None:
        self.__verbose = verbose

    # +
    # getter(s)
    # -
    @property
    def answer(self):
        return self.__answer

    @property
    def command(self):
        return self.__command

    @property
    def encoder_a(self):
        return self.__encoder_a

    @property
    def encoder_b(self):
        return self.__encoder_b

    @property
    def encoder_c(self):
        return self.__encoder_c

    @property
    def error(self):
        return self.__error

    @property
    def gfilters(self):
        return self.__gfilters

    @property
    def gfilters_names(self):
        return self.__gfilters_names

    @property
    def gfilters_numbers(self):
        return self.__gfilters_numbers

    @property
    def gfilters_slots(self):
        return self.__gfilters_slots

    @property
    def gfilter_name(self):
        return self.__gfilter_name

    @property
    def gfilter_number(self):
        return self.__gfilter_number

    @property
    def gfilter_rotating(self):
        return self.__gfilter_rotating

    @property
    def gdelta(self):
        return self.__gdelta

    @property
    def gfocus(self):
        return self.__gfocus

    @property
    def ifilters(self):
        return self.__ifilters

    @property
    def ifilters_names(self):
        return self.__ifilters_names

    @property
    def ifilters_numbers(self):
        return self.__ifilters_numbers

    @property
    def ifilters_slots(self):
        return self.__ifilters_slots

    @property
    def ifilter_inbeam(self):
        return self.__ifilter_inbeam

    @property
    def ifilter_name(self):
        return self.__ifilter_name

    @property
    def ifilter_number(self):
        return self.__ifilter_number

    @property
    def ifilter_rotating(self):
        return self.__ifilter_rotating

    @property
    def ifilter_translating(self):
        return self.__ifilter_translating

    @property
    def ifocus_a(self):
        return self.__ifocus_a

    @property
    def ifocus_b(self):
        return self.__ifocus_b

    @property
    def ifocus_c(self):
        return self.__ifocus_c

    @property
    def ifocus_mean(self):
        return self.__ifocus_mean

    @property
    def sock(self):
        return self.__sock

    # +
    # (hidden) method: __dump__()
    # -
    def __dump__(self):
        """dump(s) variable(s)"""

        pdh(f"self = {self}")
        pdh(f"self.__host = {self.__host}")
        pdh(f"self.__port = {self.__port}")
        pdh(f"self.__timeout = {self.__timeout}")
        pdh(f"self.__simulate = {self.__simulate}")
        pdh(f"self.__verbose = {self.__verbose}")

        pdh(f"self.__answer = '{self.__answer}'")
        pdh(f"self.__command = '{self.__command}'")
        pdh(f"self.__encoder_a = {self.__encoder_a}")
        pdh(f"self.__encoder_b = {self.__encoder_b}")
        pdh(f"self.__encoder_c = {self.__encoder_c}")
        pdh(f"self.__error = '{self.__error}'")
        pdh(f"self.__gfilters = {self.__gfilters}")
        pdh(f"self.__gfilters_names = {self.__gfilters_names}")
        pdh(f"self.__gfilters_numbers = {self.__gfilters_numbers}")
        pdh(f"self.__gfilters_slots = {self.__gfilters_slots}")
        pdh(f"self.__gfilter_name = '{self.__gfilter_name}'")
        pdh(f"self.__gfilter_number = {self.__gfilter_number}")
        pdh(f"self.__gfilter_rotating = {self.__gfilter_rotating}")
        pdh(f"self.__gdelta = {self.__gdelta}")
        pdh(f"self.__gfocus = {self.__gfocus}")
        pdh(f"self.__ifilters = {self.__ifilters}")
        pdh(f"self.__ifilters_names = {self.__ifilters_names}")
        pdh(f"self.__ifilters_numbers = {self.__ifilters_numbers}")
        pdh(f"self.__ifilters_slots = {self.__ifilters_slots}")
        pdh(f"self.__ifilter_inbeam = {self.__ifilter_inbeam}")
        pdh(f"self.__ifilter_name = '{self.__ifilter_name}'")
        pdh(f"self.__ifilter_number = {self.__ifilter_number}")
        pdh(f"self.__ifilter_rotating = {self.__ifilter_rotating}")
        pdh(f"self.__ifilter_translating = {self.__ifilter_translating}")
        pdh(f"self.__ifocus_a = {self.__ifocus_a}")
        pdh(f"self.__ifocus_b = {self.__ifocus_b}")
        pdh(f"self.__ifocus_c = {self.__ifocus_c}")
        pdh(f"self.__ifocus_mean = {self.__ifocus_mean}")
        pdh(f"self.__sock = None {self.__sock}")

    # +
    # method: connect()
    # -
    def connect(self) -> None:
        """connects to host:port via socket"""

        try:
            self.__sock = None
            self.__sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.__sock.connect((socket.gethostbyname(self.__host), self.__port))
            self.__sock.settimeout(self.__timeout)
        except Exception as _:
            self.__error = f"{_}"
            self.__sock = None
        else:
            self.__error = f""

    # +
    # method: disconnect()
    # -
    def disconnect(self) -> None:
        """disconnects socket"""

        if self.__sock is not None and hasattr(self.__sock, "close"):
            try:
                self.__sock.close()
            except Exception as _:
                self.__error = f"{_}"
            else:
                self.__error = f""
        self.__sock = None

    # +
    # method: converse()
    # -
    def converse(self, talk: str = f"") -> str:
        """converses across socket"""

        # send and recv data
        if talk.strip() == "":
            return f""

        # initialize variable(s)
        self.__answer = f""
        self.__error = f""

        # change command if simulate is enabled
        if self.__simulate:
            _cmd = talk.split()
            _cmd[2] = f"SIMULATE"
            self.__command = f"{' '.join(_cmd)}\r\n"
        else:
            self.__command = f"{talk}\r\n"

        # converse
        if self.__verbose:
            pdh(msg=f"\tSend> '{self.__command[:-2]}'", color="magenta", height=1)
        try:
            self.__sock.send(self.__command.encode())
            self.__answer = self.__sock.recv(BOK_NG_STRING).decode()
        except Exception as _:
            self.__answer = f""
            self.__error = f"{_}"
        else:
            self.__error = f""

        # return
        if self.__verbose:
            pdh(msg=f"\tRecv> '{self.__answer[:-1]}'", color="magenta", height=1)
        return self.__answer

    # +
    # method: parse_command_response()
    # -
    def parse_command_response(self, reply: str = "") -> bool:
        """parses command response from socket"""

        _reply = reply.upper()
        if not _reply.startswith(BOK_NG_TELESCOPE):
            return False

        elif BOK_NG_INSTRUMENT not in _reply:
            return False

        else:
            if " OK" in _reply:
                return True
            elif " ERROR" in _reply:
                self.__error = f"{_reply}".replace("\n", "")
                return False
            else:
                self.__error = f"{_reply} ERROR (unknown response)".replace("\n", "")
                return False

    # +
    # method: command_exit()
    # -
    def command_exit(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND EXIT"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND EXIT")
        return self.parse_command_response(_reply)

    # +
    # method: command_gfilter_init()
    # -
    def command_gfilter_init(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND GFILTER INIT"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND GFILTER INIT")
        return self.parse_command_response(_reply)

    # +
    # method: command_gfilter_name()
    # -
    def command_gfilter_name(self, gname: str = "") -> bool:
        """BOK 90PRIME <cmd-id> COMMAND GFILTER NAME <str>"""

        if gname.strip() == "":
            return False

        if not self.__gfilters:
            self.request_gfilters()

        if gname.strip() not in self.__gfilters_names:
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND GFILTER NAME {gname}")
        return self.parse_command_response(_reply)

    # +
    # method: command_gfilter_number()
    # -
    def command_gfilter_number(self, gnumber: int = -1) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND GFILTER NUMBER <int>"""

        if not self.__gfilters:
            self.request_gfilters()

        if gnumber not in self.__gfilters_numbers:
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND GFILTER NUMBER {gnumber}")
        return self.parse_command_response(_reply)

    # +
    # method: command_gfocus_delta()
    # -
    def command_gfocus_delta(self, gdelta: float = math.nan) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND GFOCUS DELTA <float>"""

        if math.nan < gdelta < -math.nan:
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND GFOCUS DELTA {gdelta:.4f}")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifilter_init()
    # -
    def command_ifilter_init(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFILTER INIT"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND IFILTER INIT")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifilter_load()
    # -
    def command_ifilter_load(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFILTER LOAD"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND IFILTER LOAD")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifilter_name()
    # -
    def command_ifilter_name(self, iname: str = "") -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFILTER NAME <str>"""

        if iname.strip() == "":
            return False

        if not self.__ifilters:
            self.request_ifilters()

        if iname.strip() not in self.__ifilters_names:
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND IFILTER NAME {iname}")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifilter_number()
    # -
    def command_ifilter_number(self, inumber: int = -1) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFILTER NUMBER <int>"""

        if not self.__ifilters:
            self.request_ifilters()

        if inumber not in self.__ifilters_numbers:
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND IFILTER NUMBER {inumber}")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifilter_unload()
    # -
    def command_ifilter_unload(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFILTER UNLOAD"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND IFILTER UNLOAD")
        return self.parse_command_response(_reply)

    # +
    # method: command_ifocus()
    # -
    def command_ifocus(
        self, a: float = math.nan, b: float = math.nan, c: float = math.nan, t: float = math.nan
    ) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFOCUS A <float> B <float> C <float> T <float>"""

        if (
            (math.nan < a < -math.nan)
            or (math.nan < b < -math.nan)
            or (math.nan < c < -math.nan)
            or (math.nan < t < -math.nan)
        ):
            return False

        _reply = self.converse(
            f"BOK 90PRIME {get_jd()} COMMAND IFOCUS A {a:.4f} B {b:.4f} C {c:.4f} T {t:.4f}"
        )
        return self.parse_command_response(_reply)

    # +
    # method: command_ifocus_delta()
    # -
    def command_ifocus_delta(self, idelta: float = math.nan, t: float = math.nan) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND IFOCUS DELTA <float> T <float>"""

        if (math.nan < idelta < -math.nan) or (math.nan < t < -math.nan):
            return False

        _reply = self.converse(
            f"BOK 90PRIME {get_jd()} COMMAND IFOCUS DELTA {idelta:.4f} T {t:.4f}"
        )
        return self.parse_command_response(_reply)

    # +
    # method: command_lvdt()
    # -
    def command_lvdt(
        self, a: float = math.nan, b: float = math.nan, c: float = math.nan, t: float = math.nan
    ) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND LVDT A <float> B <float> C <float> T <float>"""

        if (
            (math.nan < a < -math.nan)
            or (math.nan < b < -math.nan)
            or (math.nan < c < -math.nan)
            or (math.nan < t < -math.nan)
        ):
            return False

        _reply = self.converse(
            f"BOK 90PRIME {get_jd()} COMMAND LVDT A {a:.4f} B {b:.4f} C {c:.4f} T {t:.4f}"
        )
        return self.parse_command_response(_reply)

    # +
    # method: command_lvdtall()
    # -
    def command_lvdtall(self, lvdt: float = math.nan, t: float = math.nan) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND LVDTALL <float> T <float>"""

        if (math.nan < lvdt < -math.nan) or (math.nan < t < -math.nan):
            return False

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND LVDTALL {lvdt:.4f} T {t:.4f}")
        return self.parse_command_response(_reply)

    # +
    # method: command_test()
    # -
    def command_test(self) -> bool:
        """BOK 90PRIME <cmd-id> COMMAND TEST"""

        _reply = self.converse(f"BOK 90PRIME {get_jd()} COMMAND TEST")
        return self.parse_command_response(_reply)

    # +
    # method: request_encoders()
    # -
    def request_encoders(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST ENCODERS"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST ENCODERS")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK A=-0.355 B=1.443 C=0.345'
        elif "OK" in self.__answer:
            for _elem in self.__answer.split():
                if "A=" in _elem:
                    try:
                        self.__encoder_a = float(_elem.split("=")[1])
                    except Exception as _ea:
                        self.__error = f"{_ea}"
                        self.__encoder_a = math.nan
                    else:
                        self.__error = f""
                elif "B=" in _elem:
                    try:
                        self.__encoder_b = float(_elem.split("=")[1])
                    except Exception as _eb:
                        self.__error = f"{_eb}"
                        self.__encoder_b = math.nan
                    else:
                        self.__error = f""
                elif "C=" in _elem:
                    try:
                        self.__encoder_c = float(_elem.split("=")[1])
                    except Exception as _ec:
                        self.__error = f"{_ec}"
                        self.__encoder_c = math.nan
                    else:
                        self.__error = f""

    # +
    # method: request_gfilter()
    # -
    def request_gfilter(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST GFILTER"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST GFILTER")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__error}, {self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK SNUM=4:red ROTATING=False'
        elif "OK" in self.__answer:
            for _elem in self.__answer.split():
                if "SNUM=" in _elem:
                    try:
                        self.__gfilter_name = f"{_elem.split('=')[1].split(':')[1]}"
                        self.__gfilter_number = int(_elem.split("=")[1].split(":")[0])
                    except Exception as _eg:
                        self.__error = f"{_eg}"
                        self.__gfilter_name = f""
                        self.__gfilter_number = -1
                    else:
                        self.__error = f""
                elif "ROTATING=" in _elem:
                    try:
                        self.__gfilter_rotating = (
                            True if _elem.split("=")[1].lower() in BOK_NG_TRUE else False
                        )
                    except Exception as _er:
                        self.__error = f"{_er}"
                        self.__gfilter_rotating = f"Unknown"
                    else:
                        self.__error = f""

    # +
    # method: request_gfilters()
    # -
    def request_gfilters(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST GFILTERS"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST GFILTERS")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__error}, {self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK 1=1:green 2=2:open 3=3:neutral 4=4:red 5=5:open 6=6:blue'
        elif "OK" in self.__answer:
            self.__error, self.__gfilters = f"", {}
            for _elem in self.__answer.split():
                if "=" in _elem:
                    try:
                        _slot = int(_elem.split("=")[0])
                    except Exception as _es:
                        self.__error = f"{_es}"
                        _slot = -1
                    else:
                        self.__error = f""
                    if _slot in BOK_NG_GFILTER_SLOTS:
                        try:
                            _name = _elem.split("=")[1].split(":")[1]
                            _number = int(_elem.split("=")[1].split(":")[0])
                        except Exception as _en:
                            self.__error = f"{_en}"
                            _name = f""
                            _number = -1
                        else:
                            self.__error = f""
                            self.__gfilters = {
                                **self.__gfilters,
                                **{f"Slot {_slot}": {"Number": _number, "Name": _name}},
                            }

        # parse dictionary
        self.__gfilters_names = [_v["Name"] for _k, _v in self.__gfilters.items()]
        self.__gfilters_numbers = [_v["Number"] for _k, _v in self.__gfilters.items()]
        self.__gfilters_slots = [int(_.split()[1]) for _ in self.__gfilters]

    # +
    # method: request_gfocus()
    # -
    def request_gfocus(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST GFOCUS"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST GFOCUS")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__error}, {self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK GFOCUS=-0.355'
        elif "OK" in self.__answer:
            for _elem in self.__answer.split():
                if "GFOCUS=" in _elem:
                    try:
                        self.__gfocus = float(_elem.split("=")[1])
                    except Exception as _eg:
                        self.__error = f"{_eg}"
                        self.__gfocus = math.nan
                    else:
                        self.__error = f""

    # +
    # method: request_ifilter()
    # -
    def request_ifilter(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST IFILTER"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST IFILTER")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__error}, {self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK FILTVAL=18:Bob INBEAM=True ROTATING=False TRANSLATING=False'
        elif "OK" in self.__answer:
            self.__error = f""
            for _elem in self.__answer.split():
                if "FILTVAL=" in _elem:
                    try:
                        self.__ifilter_name = f"{_elem.split('=')[1].split(':')[1]}"
                        self.__ifilter_number = int(_elem.split("=")[1].split(":")[0])
                    except Exception as _ef:
                        self.__error = f"{_ef}"
                        self.__ifilter_name = f""
                        self.__ifilter_number = -1
                    else:
                        self.__error = f""
                elif "INBEAM=" in _elem:
                    try:
                        self.__ifilter_inbeam = (
                            True if _elem.split("=")[1].lower() in BOK_NG_TRUE else False
                        )
                    except Exception as _ei:
                        self.__error = f"{_ei}"
                        self.__ifilter_inbeam = f"Unknown"
                    else:
                        self.__error = f""
                elif "ROTATING=" in _elem:
                    try:
                        self.__ifilter_rotating = (
                            True if _elem.split("=")[1].lower() in BOK_NG_TRUE else False
                        )
                    except Exception as _er:
                        self.__error = f"{_er}"
                        self.__ifilter_rotating = f"Unknown"
                    else:
                        self.__error = f""
                elif "TRANSLATING=" in _elem:
                    try:
                        self.__ifilter_translating = (
                            True if _elem.split("=")[1].lower() in BOK_NG_TRUE else False
                        )
                    except Exception as _et:
                        self.__error = f"{_et}"
                        self.__ifilter_translating = f"Unknown"
                    else:
                        self.__error = f""

    # +
    # method: request_ifilters()
    # -
    def request_ifilters(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST IFILTERS"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST IFILTERS")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__error}, {self.__answer}"

        # parse answer , eg 'BOK 90PRIME <cmd-id> OK 0=18:Bob 1=2:g 2=3:r 3=4:i 4=5:z 5=6:u'
        elif "OK" in self.__answer:
            self.__error, self.__ifilters = f"", {}
            for _elem in self.__answer.split():
                if "=" in _elem:
                    try:
                        _slot = int(_elem.split("=")[0])
                    except Exception as _es:
                        self.__error = f"{_es}"
                        _slot = -1
                    else:
                        self.__error = f""
                    if _slot in BOK_NG_IFILTER_SLOTS:
                        try:
                            _name = _elem.split("=")[1].split(":")[1]
                            _number = int(_elem.split("=")[1].split(":")[0])
                        except Exception as _en:
                            self.__error = f"{_en}"
                            _name = f""
                            _number = -1
                        else:
                            self.__error = f""
                            self.__ifilters = {
                                **self.__ifilters,
                                **{f"Slot {_slot}": {"Number": _number, "Name": _name}},
                            }

        # parse dictionary
        self.__ifilters_names = [_v["Name"] for _k, _v in self.__ifilters.items()]
        self.__ifilters_numbers = [_v["Number"] for _k, _v in self.__ifilters.items()]
        self.__ifilters_slots = [int(_.split()[1]) for _ in self.__ifilters]

    # +
    # method: request_ifocus()
    # -
    def request_ifocus(self) -> None:
        """BOK 90PRIME <cmd-id> REQUEST IFOCUS"""

        # talk to hardware
        self.converse(f"BOK 90PRIME {get_jd()} REQUEST IFOCUS")

        # parse answer, eg 'BOK 90PRIME <cmd-id> ERROR (reason)'
        if "ERROR" in self.__answer:
            self.__error = f"{self.__answer}"

        # parse answer, eg 'BOK 90PRIME <cmd-id> OK A=355 B=443 C=345'
        elif "OK" in self.__answer:
            for _elem in self.__answer.split():
                if "A=" in _elem:
                    try:
                        self.__ifocus_a = float(_elem.split("=")[1])
                    except Exception as _ea:
                        self.__error = f"{_ea}"
                        self.__ifocus_a = math.nan
                    else:
                        self.__error = f""
                elif "B=" in _elem:
                    try:
                        self.__ifocus_b = float(_elem.split("=")[1])
                    except Exception as _eb:
                        self.__error = f"{_eb}"
                        self.__ifocus_b = math.nan
                    else:
                        self.__error = f""
                elif "C=" in _elem:
                    try:
                        self.__ifocus_c = float(_elem.split("=")[1])
                    except Exception as _ec:
                        self.__error = f"{_ec}"
                        self.__ifocus_c = math.nan
                    else:
                        self.__error = f""
                elif "MEAN=" in _elem:
                    try:
                        self.__ifocus_mean = float(_elem.split("=")[1])
                    except Exception as _em:
                        self.__error = f"{_em}"
                        self.__ifocus_mean = math.nan
                    else:
                        self.__error = f""


# +
# function: ngclient_check()
# -
def ngclient_check(
    _host: str = BOK_NG_HOST,
    _port: int = BOK_NG_PORT,
    _timeout: float = BOK_NG_TIMEOUT,
    _simulate: bool = False,
    _verbose: bool = False,
) -> None:

    # exercise command(s) and request(s)
    _client = None
    try:

        # instantiate client and connect to server
        pdh(
            msg=f"Executing> NgClient(host='{_host}', port={_port}, timeout={_timeout}, simulate={_simulate}, verbose={_verbose})",
            color="green",
            height=1,
        )
        _client = NgClient(
            host=_host, port=_port, timeout=_timeout, simulate=_simulate, verbose=_verbose
        )
        _client.connect()
        if _client.sock is not None:
            pdh(msg=f"\tInstantiation OK, sock={_client.sock}", color="green", height=1)
        else:
            pdh(msg=f"\tInstantiation FAILED, error={_client.error}", color="red", height=1)
            return

        # +
        # request(s)
        # -

        # request_encoders()
        pdh(msg=f"Executing> request_encoders()", color="green", height=1)
        _client.request_encoders()
        if _client.error == "":
            pdh(msg=f"\tencoder_a = {_client.encoder_a}", color="green", height=1)
            pdh(msg=f"\tencoder_b = {_client.encoder_b}", color="green", height=1)
            pdh(msg=f"\tencoder_c = {_client.encoder_c}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_gfilters()
        pdh(msg=f"Executing> request_gfilters()", color="green", height=1)
        _client.request_gfilters()
        if _client.error == "":
            pdh(msg=f"\tgfilters = {_client.gfilters}", color="green", height=1)
            pdh(msg=f"\tgfilters_names = {_client.gfilters_names}", color="green", height=1)
            pdh(msg=f"\tgfilters_numbers = {_client.gfilters_numbers}", color="green", height=1)
            pdh(msg=f"\tgfilters_slots = {_client.gfilters_slots}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_gfilter()
        pdh(msg=f"Executing> request_gfilter()", color="green", height=1)
        _client.request_gfilter()
        if _client.error == "":
            pdh(msg=f"\tgfilter_name = '{_client.gfilter_name}'", color="green", height=1)
            pdh(msg=f"\tgfilter_number = {_client.gfilter_number}", color="green", height=1)
            pdh(msg=f"\tgfilter_rotating = {_client.gfilter_rotating}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_gfocus()
        pdh(msg=f"Executing> request_gfocus()", color="green", height=1)
        _client.request_gfocus()
        if _client.error == "":
            pdh(msg=f"\tgfocus = {_client.gfocus}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_ifilters()
        pdh(msg=f"Executing> request_ifilters()", color="green", height=1)
        _client.request_ifilters()
        if _client.error == "":
            pdh(msg=f"\tifilters = {_client.ifilters}", color="green", height=1)
            pdh(msg=f"\tifilters_names = {_client.ifilters_names}", color="green", height=1)
            pdh(msg=f"\tifilters_numbers = {_client.ifilters_numbers}", color="green", height=1)
            pdh(msg=f"\tifilters_slots = {_client.ifilters_slots}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_ifilter()
        pdh(msg=f"Executing> request_ifilter()", color="green", height=1)
        _client.request_ifilter()
        if _client.error == "":
            pdh(msg=f"\tifilter_inbeam = {_client.ifilter_inbeam}", color="green", height=1)
            pdh(msg=f"\tifilter_name = {_client.ifilter_name}", color="green", height=1)
            pdh(msg=f"\tifilter_number = {_client.ifilter_number}", color="green", height=1)
            pdh(msg=f"\tifilter_rotating = {_client.ifilter_rotating}", color="green", height=1)
            pdh(
                msg=f"\tifilter_translating = {_client.ifilter_translating}",
                color="green",
                height=1,
            )
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # request_ifocus()
        pdh(msg=f"Executing> request_ifocus()", color="green", height=1)
        _client.request_ifocus()
        if _client.error == "":
            pdh(msg=f"\tifocus_a = {_client.ifocus_a}", color="green", height=1)
            pdh(msg=f"\tifocus_b = {_client.ifocus_b}", color="green", height=1)
            pdh(msg=f"\tifocus_c = {_client.ifocus_c}", color="green", height=1)
            pdh(msg=f"\tifocus_mean = {_client.ifocus_mean}", color="green", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # +
        # command(s)
        # -

        # command_gfilter_init()
        pdh(msg=f"Executing> command_gfilter_init() ...", color="green", height=1)
        if _client.command_gfilter_init():
            pdh(msg=f"\tcommand_gfilter_init() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_gfilter_init() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_gfilter_name()
        _gfilter_name = random.choice(_client.gfilters_names)
        pdh(msg=f"Executing> command_gfilter_name('{_gfilter_name}') ...", color="green", height=1)
        if _client.command_gfilter_name(gname=_gfilter_name):
            pdh(msg=f"\tcommand_gfilter_name('{_gfilter_name}') succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_gfilter_name('{_gfilter_name}') failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_gfilter_number()
        _gfilter_number = random.choice(_client.gfilters_numbers)
        pdh(
            msg=f"Executing> command_gfilter_number({_gfilter_number}) ...", color="green", height=1
        )
        if _client.command_gfilter_number(gnumber=_gfilter_number):
            pdh(
                msg=f"\tcommand_gfilter_number({_gfilter_number}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(msg=f"\tcommand_gfilter_number({_gfilter_number}) failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_gfilter_name('open')
        pdh(msg=f"Executing> command_gfilter_name('open') ...", color="green", height=1)
        if _client.command_gfilter_name(gname="open"):
            pdh(msg=f"\tcommand_gfilter_name('open') succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_gfilter_name('open') failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_gfocus_delta()
        _gfocus_delta = random.uniform(-100.0, 100.0)
        pdh(
            msg=f"Executing> command_gfocus_delta({_gfocus_delta:.4f}) ...", color="green", height=1
        )
        if _client.command_gfocus_delta(gdelta=_gfocus_delta):
            pdh(
                msg=f"\tcommand_gfocus_delta({_gfocus_delta:.4f}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(msg=f"\tcommand_gfocus_delta({_gfocus_delta:.4f}) failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        _gfocus_delta *= -1.0
        pdh(
            msg=f"Executing> command_gfocus_delta({_gfocus_delta:.4f}) ...", color="green", height=1
        )
        if _client.command_gfocus_delta(gdelta=_gfocus_delta):
            pdh(
                msg=f"\tcommand_gfocus_delta({_gfocus_delta:.4f}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(msg=f"\tcommand_gfocus_delta({_gfocus_delta:.4f}) failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_ifilter_init()
        # pdh(msg=f"Executing> command_ifilter_init() ...", color='green', height=1)
        # if _client.command_ifilter_init():
        #    pdh(msg=f"\tcommand_ifilter_init() succeeded", color='green', height=1)
        # else:
        #    pdh(msg=f"\tcommand_ifilter_init() failed", color='red', height=1)
        # if _verbose and _client is not None and hasattr(_client, 'answer') and hasattr(_client, 'error'):
        #    _ans, _err = _client.answer.replace('\n', ''), _client.error.replace('\n', '')
        #    pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color='blue', height=1)

        # command_ifilter_unload()
        # command_ifilter_name()
        # command_ifilter_load()
        pdh(msg=f"Executing> command_ifilter_unload() ...", color="green", height=1)
        if _client.command_ifilter_unload():
            pdh(msg=f"\tcommand_ifilter_unload() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_ifilter_unload() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        _ifilter_name = random.choice(_client.ifilters_names)
        pdh(msg=f"Executing> command_ifilter_name('{_ifilter_name}') ...", color="green", height=1)
        if _client.command_ifilter_name(iname=_ifilter_name):
            pdh(msg=f"\tcommand_ifilter_name('{_ifilter_name}') succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_ifilter_name('{_ifilter_name}') failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        pdh(msg=f"Executing> command_ifilter_load() ...", color="green", height=1)
        if _client.command_ifilter_load():
            pdh(msg=f"\tcommand_ifilter_load() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_ifilter_load() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_ifilter_unload()
        # command_ifilter_number()
        # command_ifilter_load()
        pdh(msg=f"Executing> command_ifilter_unload() ...", color="green", height=1)
        if _client.command_ifilter_unload():
            pdh(msg=f"\tcommand_ifilter_unload() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_ifilter_unload() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        _ifilter_number = random.choice(_client.ifilters_numbers)
        pdh(
            msg=f"Executing> command_ifilter_number({_ifilter_number}) ...", color="green", height=1
        )
        if _client.command_ifilter_number(inumber=_ifilter_number):
            pdh(
                msg=f"\tcommand_ifilter_number({_ifilter_number}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(msg=f"\tcommand_ifilter_number({_ifilter_number}) failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        pdh(msg=f"Executing> command_ifilter_load() ...", color="green", height=1)
        if _client.command_ifilter_load():
            pdh(msg=f"\tcommand_ifilter_load() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_ifilter_load() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_ifocus()
        _ifocus_a = random.uniform(250.0, 350.0)
        _ifocus_b = random.uniform(250.0, 350.0)
        _ifocus_c = random.uniform(250.0, 350.0)
        _tolerance = random.uniform(10.0, 20.0)
        pdh(
            msg=f"Executing> command_ifocus({_ifocus_a:.4f}, {_ifocus_b:.4f}, {_ifocus_c:.4f}, {_tolerance:.4f}) ...",
            color="green",
            height=1,
        )
        if _client.command_ifocus(a=_ifocus_a, b=_ifocus_b, c=_ifocus_c, t=_tolerance):
            pdh(
                msg=f"\tcommand_ifocus({_ifocus_a:.4f}, {_ifocus_b:.4f}, {_ifocus_c:.4f}, {_tolerance:.4f}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(
                msg=f"\tcommand_ifocus({_ifocus_a:.4f}, {_ifocus_b:.4f}, {_ifocus_c:.4f}, {_tolerance:.4f}) failed",
                color="red",
                height=1,
            )
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        _ifocus_delta = random.uniform(-50.0, 50.0)
        pdh(
            msg=f"Executing> command_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) ...",
            color="green",
            height=1,
        )
        if _client.command_ifocus_delta(idelta=_ifocus_delta, t=_tolerance):
            pdh(
                msg=f"\tcommand_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(
                msg=f"\tcommand_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) failed",
                color="red",
                height=1,
            )
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        _ifocus_delta *= -1.0
        pdh(
            msg=f"Executing> command_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) ...",
            color="green",
            height=1,
        )
        if _client.command_ifocus_delta(idelta=_ifocus_delta, t=_tolerance):
            pdh(
                msg=f"\tcommand_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) succeeded",
                color="green",
                height=1,
            )
        else:
            pdh(
                msg=f"\tcommand_ifocus_delta({_ifocus_delta:.4f}, {_tolerance:.4f}) failed",
                color="red",
                height=1,
            )
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # print(f"command_lvdt(22.0, 33.0, 44.0) {'succeeded' if _client.command_lvdt(a=22.0, b=33.0, c=44.0) else f'failed, error={_client.error}'}")
        # print(f"command_lvdtall(55.0) {'succeeded' if _client.command_lvdtall(lvdt=55.0) else f'failed, error={_client.error}'}")

        # command_test()
        pdh(msg=f"Executing> command_test() ...", color="green", height=1)
        if _client.command_test():
            pdh(msg=f"\tcommand_test() succeeded", color="green", height=1)
        else:
            pdh(msg=f"\tcommand_test() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

        # command_exit()
        pdh(msg=f"Executing> command_exit() ...", color="green", height=1)
        if _client.command_exit():
            pdh(msg=f"\tcommand_exit() succeeded", color="green", height=1)
            if _client is not None and hasattr(_client, "disconnect"):
                _client.disconnect()
            _client = None
        else:
            pdh(msg=f"\tcommand_exit() failed", color="red", height=1)
        if (
            _verbose
            and _client is not None
            and hasattr(_client, "answer")
            and hasattr(_client, "error")
        ):
            _ans, _err = _client.answer.replace("\n", ""), _client.error.replace("\n", "")
            pdh(msg=f"\tverbose> answer='{_ans}', error='{_err}'", color="blue", height=1)

    except Exception as _x:
        print(f"{_x}")
        if _client is not None and hasattr(_client, "error"):
            print(f"{_client.error}")

    # disconnect from server
    if _client is not None and hasattr(_client, "disconnect"):
        _client.disconnect()


# +
# main()
# -
if __name__ == "__main__":

    # get command line argument(s)
    _p = argparse.ArgumentParser(
        description="Galil_DMC_22x0_TCP_Read", formatter_class=argparse.RawTextHelpFormatter
    )
    _p.add_argument(
        "--commands", default=False, action="store_true", help="Show supported commands"
    )
    _p.add_argument("--host", default=f"{BOK_NG_HOST}", help="""Host [%(default)s]""")
    _p.add_argument("--port", default=BOK_NG_PORT, help="""Port [%(default)s]""")
    _p.add_argument("--timeout", default=BOK_NG_TIMEOUT, help="""Timeout (s) [%(default)s]""")
    _p.add_argument("--simulate", default=False, action="store_true", help="Simulate")
    _p.add_argument("--verbose", default=False, action="store_true", help="Verbose")
    _args = _p.parse_args()

    # noinspection PyBroadException
    try:
        if bool(_args.commands):
            with open(BOK_NG_HELP, "r") as _f:
                print(f"{_f.read()}")
        else:
            ngclient_check(
                _host=_args.host,
                _port=int(_args.port),
                _timeout=float(_args.timeout),
                _simulate=bool(_args.simulate),
                _verbose=bool(_args.verbose),
            )
    except Exception as _:
        print(f"{_}\nUse: {__doc__}")
