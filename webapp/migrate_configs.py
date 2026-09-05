"""Run before starting the service: migrate old ESP32 data and seed absent presets."""
import argparse
import shutil
from datetime import datetime, timezone
from pathlib import Path


def migrate(root):
    root = Path(root)
    old = root / 'webapp' / 'configs'
    data = root / 'data' / 'box-configs'
    target = data / 'esp32-shell'
    (data / 'pcb-screw-box').mkdir(parents=True, exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    if old.exists():
        files = [p for p in old.rglob('*') if p.is_file() and not p.name.startswith('._')]
        # Preflight the whole tree before copying; never replace a cloud configuration.
        for source in files:
            destination = target / source.relative_to(old)
            if destination.exists() and destination.read_bytes() != source.read_bytes():
                raise RuntimeError(f'配置迁移冲突，原文件已保留：{source.relative_to(old)}')
        for source in files:
            destination = target / source.relative_to(old)
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists():
                shutil.copy2(source, destination)
            if destination.read_bytes() != source.read_bytes():
                raise RuntimeError('配置迁移校验失败，原目录已保留')
        archive = root / 'data' / 'migration-history'
        archive.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        old.rename(archive / f'esp32-shell-legacy-{stamp}')
        print(f'Migrated {len(files)} files, including history, into {target}')
    for box_type in ['esp32-shell', 'pcb-screw-box']:
        destination = data / box_type
        destination.mkdir(parents=True, exist_ok=True)
        for preset in (root / 'webapp' / 'presets' / box_type).glob('*.json'):
            if not (destination / preset.name).exists():
                shutil.copy2(preset, destination / preset.name)
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    migrate(parser.parse_args().root)
