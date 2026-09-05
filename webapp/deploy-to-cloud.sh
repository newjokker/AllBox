#!/bin/sh
set -eu

SERVER="root@8.153.160.138"
REMOTE_DIR="/opt/AllBox"

# Preserve a restorable copy of the running application before replacing code.
ssh "$SERVER" 'set -e
install -d -m 0700 /opt/AllBox/deploy-history
stamp=$(date -u +%Y%m%dT%H%M%S)
cd /opt/AllBox
tar --exclude="__pycache__" -czf "deploy-history/code-$stamp.tar.gz" webapp esp32_shell.scad esp32_shell_core.scad $(if [ -f pcb_box.scad ]; then printf "%s" pcb_box.scad; fi)
'

ssh "$SERVER" "install -d -m 0755 '$REMOTE_DIR'"
rsync -az pcb_box.scad esp32_shell.scad esp32_shell_core.scad "$SERVER:$REMOTE_DIR/"
# Runtime data stays outside webapp; presets are seeded by the migration script.
rsync -az --exclude '__pycache__' --exclude '._*' --exclude 'configs/' \
    webapp/ "$SERVER:$REMOTE_DIR/webapp/"

ssh "$SERVER" 'set -e
if [ ! -d /opt/AllBox/third_party/BOSL2 ]; then
    install -d -m 0755 /opt/AllBox/third_party
    cp -a /root/.local/share/OpenSCAD/libraries/BOSL2 /opt/AllBox/third_party/BOSL2
fi
python3 -m venv /opt/AllBox/.venv
/opt/AllBox/.venv/bin/pip install --disable-pip-version-check -r /opt/AllBox/webapp/requirements.txt
# Stop writes while taking the final data snapshot and migrating paths.
systemctl stop esp32-shell-web.service
trap "systemctl start esp32-shell-web.service" EXIT
python3 - <<"PYBACKUP"
from datetime import datetime, timezone
from pathlib import Path
import shutil
root = Path("/opt/AllBox")
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
backup = root / "data" / "config-backups" / f"pre_deploy__{stamp}"
for source, name in [(root / "webapp/configs", "legacy-esp32-shell"),
                     (root / "data/box-configs", "box-configs")]:
    if source.exists():
        shutil.copytree(source, backup / name)
print(f"Configuration snapshot: {backup}")
PYBACKUP
/opt/AllBox/.venv/bin/python /opt/AllBox/webapp/migrate_configs.py
chown -R www-data:www-data /opt/AllBox/data/box-configs
install -m 0644 /opt/AllBox/webapp/esp32-shell-web.service /etc/systemd/system/esp32-shell-web.service
systemctl daemon-reload
systemctl restart esp32-shell-web.service
trap - EXIT
curl --retry 5 --retry-delay 1 --retry-connrefused --fail http://127.0.0.1:55505/health
curl --fail --silent --output /dev/null http://127.0.0.1:55505/pcb
curl --fail --silent --output /dev/null http://127.0.0.1:55505/api/pcb/config
curl --fail --silent --output /dev/null http://127.0.0.1:55505/api/pcb/configs
curl --fail --silent --output /dev/null http://127.0.0.1:55505/api/configs
'
