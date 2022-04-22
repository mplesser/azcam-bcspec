#!/usr/bin/python

import json
import socket
import sys


class get_bok_data(socket.socket):
    # Class to retreive data from the bok server on bokpop

    # lookup table for fits keywords and descriptions with
    # bokserv keywords
    keyword_header_map = (
        # Weather
        ("udome_dewpoint", "UDOMEDP", "Upper Dome Dewpoint [F]"),
        ("udome_temp", "UDOMET", "Upper Dome Temp [F]"),
        ("udome_humid", "UDOMEH", "Upper Dome Humidity [%]"),
        ("indewpoint", "INDP", "Inside Dewpoint [F]"),
        ("inhumid", "INH", "Inside Humidity [%]"),
        ("intemp", "INT", "Inside Temperature [F]"),
        ("outdewpoint", "OUTDP", "[F]"),
        ("outhumid", "OUTH", "[%]"),
        ("outtemp", "OUTT", "[F]"),
        ("mcell_dewpoint", "MCELLDP", "Mirror Cell Dewpoint"),
        ("mcell_humid", "MCELLH", "Mirror Cell Humidity [%]"),
        ("mcell_temp", "MCELLT", "Mirror Cell Temperature [F]"),
        ("wind_speed", "WSPEED", "Wind Speed [MPH]"),
        ("wind_direction", "WDIR", "Wind Direction [Degrees]"),
        # Telemetry
        ("airmass", "AIRMASS", "Airmass"),
        ("azimuth", "AZIMUTH", "Tel Azimuth [Degrees]"),
        ("declination", "DEC", "Telescope Declination"),
        ("dome", "DOME", "Dome pos [degrees]"),
        ("elevation", "ELEVAT", "Tel Elevation [degrees]"),
        ("epoch", "EPOCH", "Coordinate Epoch"),
        ("hour_angle", "HA", "Tel Hour Angle"),
        ("iis", "ROT", "Rotator Position"),
        ("julian_date", "JD", "Julian Date"),
        ("motion", "MOT", "Motion bits"),
        ("right_ascension", "RA", "Tel Right Ascension"),
        ("sidereal_time", "LST-OBS", "Local Sidereal Time"),
        ("universal_time", "UTC", "Unviversal Time"),
        ("wobble", "WOB", "Wobble"),
    )

    def __init__(self, HOST="10.30.1.3", PORT=5554, kwmap=None):
        self.host = HOST
        self.port = PORT

        if not kwmap:
            self.kwmap = self.keyword_header_map
        else:
            self.kwmap = kwmap

    def connect(self, timeout=1.0):
        socket.socket.__init__(self, socket.AF_INET, socket.SOCK_STREAM)
        if self.timeout:
            self.settimeout(timeout)
        HOST = socket.gethostbyname(HOST)
        self.connect((HOST, int(self.port)))

    def listen(self):
        # listen for incomming socket data
        test = True
        resp = ""
        while test:
            try:
                newStuff = self.recv(100)
            except socket.timeout:
                return resp

            if newStuff:
                resp += newStuff
            else:
                return resp

    def converse(self, message):
        # send socket data and then listen for a response
        self.send(message)
        return self.listen()

    def getAll(self):
        # retrieve all information from the bokpop server
        self.data = self.converse("all")
        # convert to python dict type and return.
        return json.loads(self.data)

    def putHeader(self, fitsfd):
        # use the kwmap to put in fits
        # header keywords, values and
        # descriptions in to the fits
        # header.
        all_data = self.getAll()
        for Map in self.kwmap:
            kw, fitskw, descr = Map
            val = self.extract(all_data, kw)
            print(kw, val, descr)
            try:
                # lazily look for numbers
                val = float(val)
            except ValueError:
                pass

            fitsfd[0].header[fitskw] = (val, descr)

    def extract(self, pyDict, keyword):
        # Extract fits header data from bokserver
        # using the kwmap
        for key, val in pyDict.iteritems():
            if type(val) == dict:
                resp = self.extract(val, keyword)
                if resp != None:
                    return resp
            else:
                if key == keyword:
                    return val


# instance
test_bokpop_data = get_bok_data("10.30.1.3", 5554)
