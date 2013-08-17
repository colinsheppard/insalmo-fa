#!/bin/bash.exe
set -e

cd ..
#make clean
make
cd TestInput/
../insalmo-fa.exe -b
