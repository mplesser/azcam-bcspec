"""
Contains the PrimeFocus instrument class for the UAO 90" 90prime instrument.
This version connects to NG Server for instrument control.
"""

import time
import math

import azcam
from azcam.tools.instrument import Instrument
from .Galil_DMC_22x0_NgClient import NgClient


class PrimeFocusInstrument(Instrument):
    """
    The interface to the 90prime instrument.
    The InstrumentServer is the new NG Server.
    """

    def __init__(self, tool_id="instrument", description="primefocus_ngserver"):

        super().__init__(tool_id, description)

        self.name = "90prime"
        self.host = "10.30.1.2"
        #self.host = "140.252.86.113"
        self.port = 5750
        self.simulate = False

        self.define_keywords()

    def initialize(self):

        if not self.enabled:
            azcam.AzcamWarning(f"{self.name} is not enabled")
            return

        self.iserver = NgClient(self.host, self.port, simulate=self.simulate)
        self.iserver.connect()

        #self.iserver.command_ifilter_init()

        self.initialized = True

        return

    def dump(self):
        """
        Dump instrument info.
        """

        print(f"{self.iserver.__dump__()}")

        return

    def test(self, number_cycles=1):
        """
        Test 90prime instrument.
        number_cycles is the number of cycles to repeat during testing.
        """

        raise NotImplementedError

    # *** FILTERS ***

    def get_filters(self, filter_id=0):
        """
        Return a list of all filters in wheel.
        """

        self.iserver.request_ifilters()

        return self.iserver.ifilters_names

    def get_filter(self, filter_id=0):
        """
        Reads the filter name in the beam.
        """

        self.iserver.request_ifilter()
        
        if self.iserver.ifilter_inbeam:
            filter = self.iserver.ifilter_name
        else:
            filter = 'none'

        return filter

    def set_filter(self, filter, filter_id=0):
        """
        Set the current/loaded filter.
        filter: a string containing the filter name to set.
        filter_id: the filter mechanism ID.
        """

        self.iserver.command_ifilter_unload()

        self.iserver.command_ifilter_name(filter)

        self.iserver.command_ifilter_load()

        return

    # *** FOCUS ***

    def get_focus(self, focus_id=0):
        """
        Return a single current LVDT focus position as a float.
        """

        reply = self.iserver.request_ifocus()

        focus_id = int(focus_id)

        fpos = math.nan
        if focus_id == 0:
            fpos = self.iserver.ifocus_a
        elif focus_id == 1:
            fpos = self.iserver.ifocus_b
        elif focus_id == 2:
            fpos = self.iserver.ifocus_c

        return fpos

    def get_mean_focus(self):

        reply = self.iserver.request_ifocus()

        return self.iserver.ifocus_mean

    def get_focus_all(self):
        """
        Return the 3 current LVDT instrument focus position as a string.
        Return string is formated as "*LVDT_A*LVDT_B*LVDT_C*, e.g. "*01.123*01.321*01.765*"
        """

        reply = self.iserver.request_ifocus()

        focuspositionstring = f"*{self.iserver.ifocus_a}*{self.iserver.ifocus_b}*{self.iserver.ifocus_c}*"

        return focuspositionstring

    def set_focus_all(self, focus_a, focus_b, focus_c):
        """
        Moves each of the 3 actuators for instrument focus by the amount specified, in relative stpper motor steps.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        focus_a = float(focus_a)
        focus_b = float(focus_b)
        focus_c = float(focus_c)

        self.iserver.command_ifocus_delta(focus_a, focus_b, focus_c)

        return

    def step_focus(self, focus_step, focus_id=0):
        """
        Moves all 3 actuators for instrument focus by the specified amount, in relative stepper motor steps.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        focus_step = int(float(focus_step))

        self.iserver.command_ifocus_delta(focus_step, 10)

        return

    def set_focus(self, focus_position, focus_id=0, focus_type="step"):
        """
        Move (or step) the instrument focus.
        focus_position is the focus position or step size.
        focus_id is the focus mechanism ID.
        focus_type is "absolute" or "step".
        """

        # for now, step only
        return self.step_focus(focus_position)

    # *** KEYWORDS ***

    def define_keywords(self):
        """
        Defines instrument keywords, if they are not already defined.
        """

        if len(self.header.keywords) != 0:
            return

        # add keywords to header
        keywords = [
            "FILTER",
            "FOCUSVAL",
            "LVDTA",
            "LVDTB",
            "LVDTC",
            "FOCSTART",
            "FOCSTEP",
            "FOCSHIFT",
            "FOCSTEPS",
        ]
        comments = {
            "FILTER": "Filter name",
            "FOCUSVAL": "Focus",
            "LVDTA": "LVDTA position",
            "LVDTB": "LVDTB position",
            "LVDTC": "LVDTC position",
            "FOCSTART": "Focus exposure starting focus position",
            "FOCSTEP": "Focus exposure step size",
            "FOCSHIFT": "Focus exposure detector shift lines",
            "FOCSTEPS": "Focus exposure number integrations",
        }
        types = {
            "FILTER": "str",
            "FOCUSVAL": "str",
            "LVDTA": "float",
            "LVDTB": "float",
            "LVDTC": "float",
            "FOCSTART": "str",
            "FOCSTEP": "float",
            "FOCSHIFT": "float",
            "FOCSTEPS": "float",
        }

        for key in keywords:
            self.header.set_keyword(key, None, comments[key], types[key])

        return

    def get_keyword(self, keyword):
        """
        Read an instrument keyword value.
        This command will read hardware to obtain the keyword value.
        """

        if keyword == "FOCUSVAL":
            reply = self.get_focus_all()
        elif keyword == "FILTER":
            reply = self.get_filter()
        elif keyword == "FOCUS0" or keyword == "LVDTA":
            reply = self.get_focus(0)
        elif keyword == "FOCUS1" or keyword == "LVDTB":
            reply = self.get_focus(1)
        elif keyword == "FOCUS2" or keyword == "LVDTC":
            reply = self.get_focus(2)
        else:
            try:
                reply = self.header.values[keyword]
            except Exception:
                raise azcam.AzcamError(f"keyword not defined: {keyword}")

        # convert type
        if self.header.typestrings[keyword] == "int":
            reply = int(reply)
        elif self.header.typestrings[keyword] == "float":
            reply = float(reply)

        # store value in Header
        self.header.set_keyword(keyword, reply)

        t = self.header.typestrings[keyword]

        return [reply, self.header.comments[keyword], t]

    def read_header(self):
        """
        Reads and returns current header data.
        This method looks up all keywords and queries hardware for the current value of each keyword.
        Returns [Header[]]: Each element Header[i] contains the sublist (keyword, value, comment, and type).
        Example: Header[2][1] is the value of keyword 2 and Header[2][3] is its type.
        Type is one of 'str', 'int', 'float', or 'complex'.
        """

        if not self.enabled:
            azcam.AzcamWarning("instrument not enabled")
            return

        header = []
        reply = self.header.get_keywords()

        for key in reply:
            try:
                reply = self.get_keyword(key)
            except Exception:
                continue
            list1 = [key, reply[0], reply[1], reply[2]]
            header.append(list1)

        return header

    # *** GUIDER ***

    def guider_init(self):
        """
        Initialize guider camera.
        """

        self.iserver.command_gfilter_init()

        return

    def set_guider_focus(self, steps):
        """
        Move guider focus the specified number of steps.
        """

        self.iserver.command_gfocus_delta(steps)

        return

    def get_guider_focus(self):
        """
        Get guider focus position.
        """

        self.iserver.request_gfocus()

        return self.iserver.gfocus

    def set_guider_filter(self, filter_number):
        """
        Move guider filter wheel to position number.
        """

        self.iserver.command_gfilter_number(filter_number)

        return

    def get_guider_filter(self, filter_id=0):
        """
        Returns the current guider filter number.
        """

        self.iserver.request_gfilter()

        return self.iserver.gfilter_name
