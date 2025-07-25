#!/bin/bash
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043
# Check that all shell scripts are executable

set -e

echo "Checking script permissions..."

# Find all .sh files and check if they're executable
find . -name "*.sh" -not -path "./.git/*" | while read -r file; do
    if [[ ! -x "$file" ]]; then
        echo "Script $file is not executable. Run: chmod +x $file"
        exit 1
    fi
done

echo "All scripts have correct permissions."
