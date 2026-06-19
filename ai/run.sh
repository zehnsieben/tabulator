#!/usr/bin/env bash

set -euo pipefail

open -n DerivedData/Build/Products/Debug/AltTab.app --args --logs=debug --benchmark showUi 3
