# BokData class from Scott
# 10Sep17 - last change MPL

import json
import socket


class BokData(socket.socket):
    # Class to retreive data from the bok server on bokpop

    # lookup table for fits keywords and descriptions with bokserv keywords
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
        ("universal_time", "UTC", "Universal Time"),
        ("wobble", "WOB", "Wobble"),
    )

    def __init__(self, HOST="10.30.1.3", PORT=5554, timeout=1.0):

        # self.timeout=timeout
        self.host = HOST
        self.port = PORT

        self.kwmap = self.keyword_header_map

        socket.socket.__init__(self, socket.AF_INET, socket.SOCK_STREAM)

    def listen(self):
        # listen for incomming socket data
        test = True
        resp = ""
        while test:
            try:
                newStuff = self.recv(100).decode()
            except socket.timeout:
                return resp

            if newStuff:
                resp += newStuff
            else:
                return resp

    def converse(self, message):
        # send socket data and then listen for a response
        self.send(str.encode(message))
        return self.listen()

    def getAll(self):
        # retrieve all information from the bokpop server
        self.data = self.converse("all\n")  # added per Scott 24jan20
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

    def makeHeader(self):
        # use the kwmap to put in fits
        # header keywords, values and
        # descriptions in to the fits
        # header.
        # all_data = self.getAll()

        all_data = self.get_header_data()
        header = []
        for Map in self.kwmap:
            kw, fitskw, descr = Map
            val = self.extract(all_data, kw)
            try:
                # lazily look for numbers
                val = float(val)
            except ValueError:
                pass
            except:
                pass

            keyword1 = fitskw
            value1 = val
            comment1 = '"' + descr + '"'

            header.append([keyword1, value1, comment1])

            if keyword1 == "LST-OBS":
                header.append(["ST", value1, '"local siderial time"'])

        return header

    def extract(self, pyDict, keyword):
        # Extract fits header data from bokserver
        # using the kwmap
        for key, val in pyDict.items():
            if type(val) == dict:
                resp = self.extract(val, keyword)
                if resp != None:
                    return resp
            else:
                if key == keyword:
                    return val

    def get_header_data(self):
        """
        Added for AzCam
        """

        # open socket
        socket.socket.__init__(self, socket.AF_INET, socket.SOCK_STREAM)
        if self.timeout:
            self.settimeout(self.timeout)
        HOST = socket.gethostbyname(self.host)
        self.connect((HOST, int(self.port)))

        # get data
        reply = self.getAll()

        # output
        return reply

    def update_header(self):
        """
        Update instrument header.
        """

        data = self.makeHeader()

        return


"""
example of data

{u'upper_dome': {u'udome_humid': 58.51, u'timestamp': u'2016-08-31 16:32:13.432139+00:00', u'udome_dewpoint': 53.15, u'udome_temp': 68.27},
u'dome_state': {u'timestamp': u'2016-08-31 16:32:20.489121+00:00', u'dome_open': 0.0, u'dome_closed': 1.0}, 
u'tube_temps': {u'ninety_prime': -994.0, u'north_strut': 66.3, u'primary_mirror': 66.7, u'timestamp': u'2016-08-31 16:32:20.276327+00:00'}, 
u'iis': {u'timestamp': u'2016-08-31 16:32:20.542472+00:00', u'iispos': -994}, 
u'mirror_cell': {u'timestamp': u'2016-08-31 16:32:14.713395+00:00', u'mcell_dewpoint': 53.78, u'mcell_humid': 61.23, u'mcell_temp': 67.55}, 
u'wind': {u'wind_speed': 7.15, u'wind_gust_direction': 133.65, u'wind_direction': 106.98, u'wind_gust': 13.02, u'timestamp': u'2016-08-31 16:32:20.483598+00:00'}, 
u'telem': {u'airmass': u'1.00', u'elevation': u'90.0', u'iis': u'0.0', u'sidereal_time': u'07:46:55', u'wobble': u'1', u'right_ascension': u'07:45:54.08', u'dome': u'-45.7', u'motion': u'0', u'epoch': u'HD2000.000', u'declination': u'+31:50:00.0', u'hour_angle': u'-00:00:00', u'timestamp': u'2016-08-31 16:32:19.830680+00:00', u'azimuth': u'+40.2', u'universal_time': u'16:32:13.2', u'julian_date': u'2457632.1'}, 
u'inside_outside': {u'outdewpoint': 57.74, u'outhumid': 58.47, u'timestamp': u'2016-08-31 16:32:20.195288+00:00', u'outtemp': 73.22, u'indewpoint': 53.96, u'inhumid': 47.36, u'intemp': 75.38}
}
"""
