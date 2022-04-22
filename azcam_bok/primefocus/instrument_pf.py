"""
Contains the PrimeFocus instrument class for the UAO 90" 90prime instrument.
"""

# SHOW FILTISIN
# returns 0 (0.0000?) none, 1 in beam, 3 jammed

import socket
import time

import azcam
from azcam.tools.instrument import Instrument


class PrimeFocusInstrument(Instrument):
    """
    The interface to the 90prime instrument.
    The InstrumentServer is the galil, later Jeff Fookson's Ruby Galil server.
    """

    def __init__(self, tool_id="instrument", description="primefocus"):

        super().__init__(tool_id, description)

        self.Name = "90prime"
        self.name = "90prime"
        self.Port = 9874  # port for galil server on bok
        self.host = "10.30.1.2"  # bok
        self.ActiveComps = [""]
        self.InstalledFilters = {}
        self.ActiveFilter = "unknown"  # current filter

        self.Locked = False  # communications lock for galilserver

        self.focus_device = "instrument"

        # instrument server interface
        self.Iserver = InstrumentServerInterface(self.host, self.Port, self.Name)
        self.Iserver.Timeout = 20

        # add keywords
        self.define_keywords()

    def initialize(self):

        if not self.enabled:
            azcam.AzcamWarning(f"{self.name} is not enabled")
            return

        # execute a command to make sure communication is OK
        self.get_focus()

        self.initialized = True

        return

    def test(self, number_cycles=1):
        """
        Test 90prime instrument.
        number_cycles is the number of cycles to repeat during testing.
        """

        for loop in range(number_cycles):

            if number_cycles > 1:
                azcam.log(("   *** Test cycle: %d" % loop))

            # test Galil interface
            azcam.log("Testing 90prime Galil instrument interface...")

            self.initialize()

            # read current value of keywords
            for key in self.header.get_keywords():
                azcam.log(("Keyword: %s has value: %s" % (key, self.get_keyword(key)[1])))

            reply = self.get_filter()
            azcam.log(("Filter is %s" % reply))

            reply = self.get_focus()
            azcam.log(("Focus is %s" % reply))

            azcam.log("Finished testing 90prime Galil interface. OK")
            azcam.utils.prompt("Press Enter to continue...")

        return

    def command(self, Command):
        """
        Command interface for instrument.
        """

        while self.Locked:
            time.sleep(0.01)

        self.Locked = True

        reply = self.Iserver.open()
        reply = self.Iserver.recv(-2)  # read 'connected..' string and ignore
        reply = reply[1]

        reply = self.Iserver.send(Command, "")  # no terminator

        reply = self.Iserver.recv(-2)
        reply = reply[1]

        self.Iserver.send("CLIENTDONE", "")
        self.Iserver.recv(-2)  # read 'shutting down...' string and ignore

        self.Iserver.close()

        # check for error, valid replies starts with 'OK: ' and errors with '?: '
        if reply.startswith("OK: "):
            reply = reply[4:]
            self.Locked = False
            self.Iserver.close()  # new
            return reply
        else:
            self.Locked = False
            self.Iserver.close()  # new
            return reply

    # *** FILTERS ***

    def get_filters(self, filter_id=0):
        """
        Return a list of all filters in wheel.
        """

        reply = self.command("SHOWFILTERS")  # returns space deliminated names

        self.InstalledFilters = reply.split(" ")  # make a list

        return self.InstalledFilters

    def check_filter(self, filter_id=0):
        """
        Returns TRUE if a filter is loaded in the beam.
        """

        # SHOW FILTISIN
        # returns 0 (0.0000?) none, 1 in beam, 3 jammed

        reply = self.command("SHOW FILTISIN")

        if reply.startswith(" 1"):
            return True
        else:
            return False

    def get_filter(self, filter_id=0):
        """
        Reads the filter name in the beam.
        The returned filter name string is in the form "FilterName in beam", e.g. "U in beam"
        """

        if not self.check_filter(filter_id):
            return "none"

        reply = self.command("SHOWLOADEDFILTER")

        CurrentFilterName = reply
        self.ActiveFilter = CurrentFilterName

        return CurrentFilterName

    def set_filter(self, Filter, filter_id=0):
        """
        Set the current/loaded filter, typically the filter in the beam.
        Filter: a string containing the filter name to set.
        filter_id: the filter mechanism ID.
        """

        reply = self.get_filter(filter_id)
        currentfilter = reply

        if currentfilter == Filter:
            azcam.log("Already at filter", currentfilter)
            return

        azcam.log("Unloading filter", currentfilter)
        cmd = "SUNLOADFILT"
        reply = self.command(cmd)

        time.sleep(10)

        azcam.log("Loading filter", Filter)
        cmd = "SLOADFILT %s" % Filter
        reply = self.command(cmd)

        time.sleep(10)
        reply = self.get_filter(filter_id)
        azcam.log("Current filter is", reply)

        return

    # *** FOCUS ***

    def get_mean_focus(self):
        focus = self.get_focus_all()
        focus = focus[1:-1].split("*")
        a, b, c = map(float, focus)
        mean = int(1000 * (a + b + c) / 3.0)
        return mean

    def step_focus(self, FocusPosition, focus_id=0):
        """
        Moves all 3 actuators for instrument focus by the specified amount, in relative stepper motor steps.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        cmd = "ALLFOCUS %d" % int(FocusPosition)

        self.command(cmd)

        mean0 = self.get_mean_focus()
        for i in range(5):
            mean = self.get_mean_focus()
            delta = abs(mean - mean0)
            if delta < 2:
                break
            else:
                pass
                # azcam.log(f'mean focus change: {delta}')

        return

    def set_focus(self, FocusPosition, focus_id=0, focus_type="step"):
        """
        Moves an individual actuators for instrument focus by the specified amount, in relative stepper motor steps.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        FocusPosition = int(float(FocusPosition))

        cmd = "ALLFOCUS %d" % (FocusPosition)  # wrong, change this

        self.command(cmd)

        return

    def set_focus_all(self, FocusPositionA, FocusPositionB, FocusPositionC):
        """
        Moves each of the 3 actuators for instrument focus by the amount specified, in relative stpper motor steps.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        cmd = "FOCUS %d %d %d" % (FocusPositionA, FocusPositionB, FocusPositionC)

        self.command(cmd)

        return

    def set_actuators(self, LvdtA, LvdtB, LvdtC):
        """
        Moves each of the 3 instrument focus actuators to the absolute value of the specified LVDT.
        One focus actuator step is 2.645 microns, which corresponds to -0.0005 LVDT units. So the conversion is (-1322.5 um/LVDT unit).
        """

        loops = 10  # number of iterations performed
        tolerance = 0.005  # allowed LVDT error
        scale = [-0.0005, -0.0005, -0.0005]  # LVDT to steps scale for A,B,C

        for i in range(loops):

            # get current values
            reply = self.get_focus_all()
            time.sleep(0.1)

            focus = reply[1].split("*")[1:]  # list of values
            for i, f in enumerate(focus):  # make floats
                focus[i] = float(f)

            # convert to stepper motor steps
            steps = [0, 0, 0]
            a = LvdtA - focus[0]
            if abs(a) > tolerance:
                steps[0] = int(a / scale[0])
            else:
                steps[0] = 0

            b = LvdtB - focus[1]
            if abs(b) > tolerance:
                steps[1] = int(b / scale[1])
            else:
                steps[1] = 0

            c = LvdtC - focus[2]
            if abs(c) > tolerance:
                steps[2] = int(c / scale[2])
            else:
                steps[2] = 0

            cmd = "FOCUS %d %d %d" % (steps[0], steps[1], steps[2])

            # stop when no correction required
            if max(steps) == 0 and min(steps) == 0:
                break

            reply = self.command(cmd)

            # get new values
            reply = self.get_focus_all()
            azcam.log(("LVDT read: %s" % reply))

            focus = reply[1].split("*")[1:]  # list of values
            for i, f in enumerate(focus):  # make floats
                focus[i] = float(f)
            # error = [LvdtA - focus[0], LvdtB - focus[1], LvdtC - focus[2]]

        return

    def get_focus(self, focus_id=0):
        """
        Return a single current LVDT focus position as a float.
        """

        focus_id = int(focus_id)

        reply = self.get_focus_all()
        reply = reply.strip()
        FocusPosition = reply.split("*")[1:]

        return FocusPosition[focus_id]

    def get_focus_all(self):
        """
        Return the 3 current LVDT instrument focus position as a string.
        Return string is formated as "*LVDT_A*LVDT_B*LVDT_C*, e.g. "*01.123*01.321*01.765*"
        """

        cmd = "SHOWALLLVDTVALS"  # current LVDT values

        reply = self.command(cmd)

        focuspositionstring = reply.replace(" ", "*")

        return focuspositionstring

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
            reply = self.get_filter(1)
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

        cmd = "INITGCAM"
        self.command(cmd)
        time.sleep(10)

        return

    def set_guider_focus(self, Steps):
        """
        Move guider focus the specified number of steps.
        """

        cmd = "GFOCUS " + str(Steps)
        reply = self.command(cmd)
        time.sleep(10)

        return reply

    def set_guider_filter(self, FilterNumber):
        """
        Move guider filter wheel to position number.
        """

        cmd = "SETGFILTER " + str(FilterNumber)
        self.command(cmd)
        time.sleep(10)

        return

    def get_guider_filter(self, filter_id=0):
        """
        Returns the current guider filter number.
        """

        cmd = "GETGFILTER"
        reply = self.command(cmd)
        CurrentFilterName = reply

        return CurrentFilterName

    # *** raw command to Galil, usually for testing only ***

    def send_raw(self, Command):
        """
        Send a raw galil command to the server.
        """

        cmd = "SENDRAW " + str(Command)
        reply = self.command(cmd)

        return reply


# *** instrument server interface ***


class InstrumentServerInterface(object):
    """
    Communicates with J. Fookson's 90prime insturment server using a socket.
    Responses from the server are in the form "OK:", "OK: message",  or "?: error message".
    Compound command may respond as "OK: OK:"
    """

    def __init__(self, Host, Port, Name):

        self.host = Host
        self.Port = Port
        self.Name = Name
        self.Timeout = 60.0  # socket timeout in seconds

    def open(self):
        """
        Open a socket connection to an instrument.
        Creates the socket and makes a connection.
        @return AzCamStatus
        """

        self.Socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.Socket.settimeout(float(self.Timeout))
        try:
            self.Socket.connect((self.host, self.Port))
            return
        except Exception:
            self.close()
            azcam.AzcamError("instrument not opened")

    def close(self):
        """
        Close an open socket connection to an instrument.
        """

        try:
            self.Socket.close()
        except Exception as message:
            azcam.log(message)
            pass

        return

    def command(self, Command, Terminator="\r\n"):
        """
        Communicte with the remote instrument server.
        Opens and closes the socket each time.
        Returns the exact reply from the server.
        """

        reply = self.open()
        reply = self.send(str.encode(Command, Terminator))
        if reply[0] == "OK":
            reply = self.recv(-1, "\n").decode()

            self.close()

        return reply

    def command1(self, Command, Terminator="\r\n"):
        """
        Communicte with the remote instrument server.
        Opens and closes the socket each time.
        Returns the exact reply from the server.
        """

        reply = self.open()
        reply = self.send(str.encode(Command, Terminator))
        reply = self.recv(256, "\n").decode()
        self.close()

        return reply

    def send(self, Command, Terminator="\r\n"):
        """
        Send a command string to a socket instrument.
        Appends the terminator.
        """

        try:
            self.Socket.send(str.encode(Command + Terminator))  # send command with terminator
            return
        except Exception:
            raise azcam.AzcamError("could not send command to instrument")

    def recv(self, Length=-1, Terminator="\n"):
        """
        Receives a reply from a socket instrument.
        Terminates the socket read when Length bytes are received or when the Terminator is received.
        @param Length is the number of bytes to receive.  -1 means receive through Terminator character.
        @param Terminator is the terminator character.
        """

        if Length == -2:
            try:
                msg = self.Socket.recv(1024).decode()
                return ["OK", msg]
            except Exception:
                return ["OK", ""]

        # receive Length bytes
        if Length != -1:
            msg = self.Socket.recv(Length).decode()
            return ["OK", msg]

        # receive with terminator
        msg = chunk = ""
        loop = 0
        while chunk != Terminator:  # CR LF is usually '\n' when translated
            try:
                chunk = self.Socket.recv(1).decode()
            except Exception:
                return ["ERROR", '"error in instrument server communication"']
            if chunk != "":
                msg = msg + chunk
                loop = 0
            else:
                loop += 1
                if loop > 10:
                    return ["ERROR", '"error in instrument server communication loop"']

        Reply = msg[:-2]  # remove CR/LF
        if Reply is None:
            Reply = ""

        return ["OK", Reply]
