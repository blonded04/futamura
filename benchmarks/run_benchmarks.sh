#!/bin/bash

for file in *.lama; do
    if [ -f "$file" ]; then
        # execute lamac version:
        lamac "${file}"
        echo "* ${file%} lamac:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./${file%.*}
        # execute ASM interpreter version:
        lamac -b "${file}"
        echo "* ${file%} ASM interpreter:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./../byterun/byterun ${file%.*}.bc
        # execute C interpreter version:
        lamac -b "${file}"
        echo "* ${file%} C interpreter:"
        /usr/bin/time --format "\treal: %E" taskset -c 0 ./../build/interpreter ${file%.*}.bc
        # execute spec version:
        echo "* ${file%} spec:"
        # TODO: build ${file%.}.bc
        # TODO: run ${file%.}.s
        echo "-----------------------------------"
    fi
done
