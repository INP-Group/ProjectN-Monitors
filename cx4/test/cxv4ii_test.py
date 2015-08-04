#!/usr/bin/env python


# imports for testing
import time
import sys
from PyQt5 import QtCore

from monitors.cx4.cython_wrapper import ccda
import signal

t1 = time.time()

nchans = 1000
i = 0

def printval(chan):
    global i
    i += 1
    if i == 5000:
        print(chan.val)
        t2 = time.time()
        print("time = %f " % (t2-t1))
        app.quit()

signal.signal(signal.SIGINT, signal.SIG_DFL)

app = QtCore.QCoreApplication(sys.argv)

context = ccda.cda_context("cx::mid:60.NAME")

chans = []

for x in range(nchans):
    chans.append(ccda.sichan(context, "", "%d" % x))

for x in chans:
    x.valueChanged.connect(printval)


sys.exit(app.exec_())