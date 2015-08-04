# -*- encoding: utf-8 -*-
from functools import partial

import time
import sys
import signal

from PyQt4 import QtCore
from monitors.cx4.cython_wrapper import ccda


i = 0
def printval(app, t1, chan):
    global i
    i += 1
    if i == 50:
        print(chan.val)
        t2 = time.time()
        print("time = %f " % (t2 - t1))
        app.quit()

def processing(app, chan):
    print(chan.val)
    app.quit()

def main():
    app = QtCore.QCoreApplication(sys.argv)
    t1 = time.time()
    nchans = 10

    chans = []
    for x in range(nchans):
        channel = ccda.sdchan(None, "", "cx::127.0.0.1:60.NAME.%d" % x)
        chans.append(channel)
        # channel.valueMeasured.connect(partial(printval, app, t1))
        channel.valueMeasured.connect(partial(processing, app))

    sys.exit(app.exec_())


if __name__ == '__main__':
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    main()
