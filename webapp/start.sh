#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ]; then
  python3 -m venv "$PROJECT_DIR/.venv"
  "$PROJECT_DIR/.venv/bin/pip" install -r "$PROJECT_DIR/webapp/requirements.txt"
fi
if [ -z "${OPENSCAD_BIN:-}" ] && [ -x /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD ]; then
  OPENSCAD_BIN=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
  export OPENSCAD_BIN
fi
cd "$PROJECT_DIR"
exec "$VENV_PYTHON" webapp/app.py
