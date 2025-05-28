#!/bin/sh

echo "Running test script"
/bin/sh /home/finder-test.sh
rc=$?
if [ $rc -eq 0 ]; then
    echo "Completed with success!!"
else
    echo "Completed with failure, failed with rc=${rc}"
fi

echo "finder-app execution complete, dropping to terminal"
/bin/sh

