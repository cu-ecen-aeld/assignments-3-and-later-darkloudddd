#!/bin/sh

set -e
set -u

WRITER=writer       # Should be installed in /usr/bin and in $PATH
FINDER=finder       # Should be installed in /usr/bin and in $PATH
TMP_DIR="/tmp/aesd_test"
WRITEFILE="${TMP_DIR}/testfile.txt"
WRITESTR="This is a test string"
RESULTFILE="/tmp/assignment4-result.txt"

# Ensure writer is in PATH
if ! command -v "$WRITER" >/dev/null 2>&1; then
    echo "Error: writer not found in PATH."
    exit 1
fi

# Ensure finder is in PATH
if ! command -v "$FINDER" >/dev/null 2>&1; then
    echo "Error: finder not found in PATH."
    exit 1
fi

# Create test directory and write file
mkdir -p "$TMP_DIR"
"$WRITER" "$WRITEFILE" "$WRITESTR"

# Validate file content
if [ ! -f "$WRITEFILE" ]; then
    echo "Error: File was not created!"
    exit 1
fi

READSTR=$(cat "$WRITEFILE")
if [ "$READSTR" != "$WRITESTR" ]; then
    echo "Error: File content does not match expected string!"
    exit 1
fi

# Run finder, output to result file
"$FINDER" "$TMP_DIR" "$WRITESTR" > "$RESULTFILE"

echo "All tests passed!"
exit 0
