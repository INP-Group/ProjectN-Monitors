#!/usr/bin/env sh

CX_FOLDER="/home/warmonger/Develop/Groups/INP/cx"
CFLAGS="-I$CX_FOLDER/4cx/src/include"  \
LDFLAGS="-L$CX_FOLDER/4cx/src/lib/4PyQt"     \
python setup.py build_ext -i