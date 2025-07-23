#!/bin/bash
# Copyright (C) 2025 Bryce Thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


set -e

if [ -n "$GGH_IGNORE_SIGNEDOFF" ]; then
    echo "ggh-signed-off: ignoring due to override"
    exit 0
fi

COMMIT_MSG="$(cat "$1")"

SIGNEDOFF_REGEX=".*Signed-off-by: .* <.*>[[:space:]]*"

# File containing the commit message
if ! [[ $COMMIT_MSG =~ $SIGNEDOFF_REGEX ]]; then
    echo "ggh-signed-off: commit does not match conventional standard, aborting" >&2
    exit 1
else
    echo "ggh-signed-off: valid commit"
fi