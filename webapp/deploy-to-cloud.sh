#!/bin/sh
set -eu

SERVER="root@8.153.160.138"
REMOTE_DIR="/opt/AllBox"

# Every deployment snapshots the server-side runtime configurations first.
ssh "$SERVER" 'python3 - <<"PY"
from datetime import datetime, timezone
from pathlib import Path
import shutil

source = Path("/opt/AllBox/webapp/configs")
files = [path for path in source.glob("*.json") if not path.name.startswith("._")]
if files:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    target = Path("/opt/AllBox/config-history") / f"pre_deploy__{stamp}"
    target.mkdir(parents=True, exist_ok=False)
    for path in files:
        shutil.copy2(path, target / path.name)
    print(f"Backed up {len(files)} configurations to {target}")
PY'

ssh "$SERVER" "install -d -m 0755 '$REMOTE_DIR' '$REMOTE_DIR/webapp/configs'"
rsync -az esp32_shell.scad esp32_shell_core.scad "$SERVER:$REMOTE_DIR/"
rsync -az --exclude '__pycache__' --exclude '._*' --exclude 'configs/' \
    webapp/ "$SERVER:$REMOTE_DIR/webapp/"

# Presets are seeded only when present and absent remotely. Runtime edits on the server always win.
set -- webapp/configs/esp32_*.json
if [ -e "$1" ]; then
    rsync -az --ignore-existing "$@" "$SERVER:$REMOTE_DIR/webapp/configs/"
fi

ssh "$SERVER" 'set -e
chmod 0755 /opt/AllBox /opt/AllBox/webapp
chmod 0644 /opt/AllBox/esp32_shell.scad /opt/AllBox/esp32_shell_core.scad
find /opt/AllBox/webapp -type d -exec chmod 0755 {} +
find /opt/AllBox/webapp -type f -exec chmod 0644 {} +
if [ ! -d /opt/AllBox/third_party/BOSL2 ]; then
    install -d -m 0755 /opt/AllBox/third_party
    cp -a /root/.local/share/OpenSCAD/libraries/BOSL2 /opt/AllBox/third_party/BOSL2
fi
python3 -m venv /opt/AllBox/.venv
/opt/AllBox/.venv/bin/pip install --disable-pip-version-check -r /opt/AllBox/webapp/requirements.txt
chown -R www-data:www-data /opt/AllBox/webapp/configs
install -m 0644 /opt/AllBox/webapp/esp32-shell-web.service /etc/systemd/system/esp32-shell-web.service
systemctl daemon-reload
systemctl restart esp32-shell-web.service
curl --retry 5 --retry-delay 1 --retry-connrefused --fail http://127.0.0.1:55505/health
'
