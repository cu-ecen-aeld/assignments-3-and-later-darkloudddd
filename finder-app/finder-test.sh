#!/bin/bash

set -e  # Exit on any error
set -u  # Treat unset variables as an error

# Variables
WRITER_APP="./writer"
FINDER_APP="./finder.sh"
TMP_DIR="/tmp/aesd_test"
WRITEFILE="${TMP_DIR}/testfile.txt"
WRITESTR="This is a test string"

# Move to the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
make clean || true

# Compile writer application
echo "Compiling writer application..."
make

# Ensure the writer app exists
if [ ! -f "$WRITER_APP" ]; then
    echo "Error: writer binary not found after compilation!"
    exit 1
fi

# Create test directory
mkdir -p "$TMP_DIR"

# Use writer application instead of writer.sh
echo "Running writer application..."
"$WRITER_APP" "$WRITEFILE" "$WRITESTR"

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

echo "Test passed: writer successfully created and wrote to the file."

# Run finder.sh (if applicable)
if [ -f "$FINDER_APP" ]; then
    echo "Running finder.sh..."
    "$FINDER_APP" "$TMP_DIR" "$WRITESTR"
else
    echo "Warning: finder.sh not found. Skipping finder test."
fi

echo "All tests passed!"
exit 0

