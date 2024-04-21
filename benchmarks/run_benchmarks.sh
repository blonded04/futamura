#!/bin/bash

for file in *.lama; do
    if [ -f "$file" ]; then
        # execute lamac version:
        lamac "${file}"
        echo "${file%} lamac:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./${file%.*}
        # # execute byterun version:
        # lamac -bc "${file%.lama}"
        # echo "${file%} byterun:"
        # /usr/bin/time --format "\treal: %E" taskset -c 0 ../byterun/byterun ${file%}.bc
        # # execute spec version:
        # # TODO: add spec version here!!!
        # echo "${file%} spec:"
        # /usr/bin/time --format "\treal: %E" taskset -c 0 ../spec/spec ${file%}.bc
    fi
done
