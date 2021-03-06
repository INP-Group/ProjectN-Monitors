#!/usr/bin/env python


# imports for testing
import time
import sys
from PyQt4 import QtCore


from monitors.cx4.cython_wrapper import ccda
import signal

t1 = time.time()

nchans = 10
i = 0

def printval(chan):
    global i
    i += 1
    if i == 50:
        print(chan.val)
        t2 = time.time()
        print("time = %f " % (t2-t1))
        app.quit()

signal.signal(signal.SIGINT, signal.SIG_DFL)

app = QtCore.QCoreApplication(sys.argv)


chans = []
for x in range(nchans):
    chans.append(ccda.sdchan(None, "", "cx::127.0.0.1:60.NAME.%d" % x))


for x in chans:
    x.valueMeasured.connect(printval)


sys.exit(app.exec_())