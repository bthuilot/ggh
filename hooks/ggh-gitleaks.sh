#!/bin/bash
# Copyright (C) 2025 Bryce Thuilot <bryce@thuilot.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


if [ -n "$GGH_IGNORE_GITLEAKS" ]; then
    echo "ggh-gitleaks: ignoring due to override"
    exit 0
fi

if ! command -v gitleaks >/dev/null 2>&1
then
    echo "gitleaks not installed, skipping" >&2
    exit 0
fi

gitleaks git --pre-commit --redact --staged --verbose
