#!/bin/bash

for file in *.lama; do
    if [ -f "$file" ]; then
        # execute lamac version:
        lamac "${file}"
        echo "* ${file%} lamac:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./${file%.*}
        # execute byterun version:
        lamac -b "${file}"
        echo "* ${file%} byterun:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./../byterun/byterun ${file%.*}.bc
        # execute spec version:
        echo "* ${file%} spec:"
        # TODO: build ${file%.}.bc
        # TODO: run ${file%.}.s
        echo "-----------------------------------"
    fi
done
