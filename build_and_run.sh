#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
"${PROJECT_DIR}/scripts/build_app.sh"
