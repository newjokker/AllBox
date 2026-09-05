"""Named configuration files, isolated by box type, with atomic writes and history."""
import hashlib
import json
import re
import shutil
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path

LOCK = threading.RLock()


class ConfigStore:
    def __init__(self, directory, box_type):
        self.directory = Path(directory)
        self.box_type = box_type

    def name(self, value):
        if not isinstance(value, str) or not value.strip():
            raise ValueError('请填写配置名称')
        value = value.strip()
        if len(value) > 60 or any(ord(c) < 32 or c in '/\\' for c in value):
            raise ValueError('配置名称最多 60 个字符，不能包含斜杠或控制字符')
        return value

    def path(self, name):
        name = self.name(name)
        slug = re.sub(r'[^\w-]+', '_', name).strip('._') or 'config'
        digest = hashlib.sha256(name.encode()).hexdigest()[:12]
        return self.directory / f'{slug}__{digest}.json'

    def list(self):
        entries = []
        for path in self.directory.glob('*.json'):
            if path.name.startswith('._'):
                continue
            try:
                data = json.loads(path.read_text(encoding='utf-8'))
                if isinstance(data, dict) and isinstance(data.get('config'), dict) and data.get('box_type') == self.box_type:
                    entries.append({'name': self.name(data['name']), 'saved_at': data.get('saved_at')})
            except (OSError, ValueError, KeyError):
                continue
        return sorted(entries, key=lambda item: item['name'])

    def load(self, name):
        path = self.path(name)
        if not path.exists():
            raise FileNotFoundError('配置不存在')
        try:
            data = json.loads(path.read_text(encoding='utf-8'))
        except (ValueError, UnicodeError):
            raise ValueError('配置文件无法读取')
        if not isinstance(data, dict) or data.get('box_type') != self.box_type or not isinstance(data.get('config'), dict):
            raise ValueError('配置类型或内容无效')
        return data

    def backup(self, path):
        if not path.exists():
            return None
        history = self.directory / 'history'
        history.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        backup = history / f'{path.stem}__{stamp}__{uuid.uuid4().hex[:8]}.json'
        shutil.copy2(path, backup)
        return backup.name

    def save(self, name, config):
        name = self.name(name)
        with LOCK:
            self.directory.mkdir(parents=True, exist_ok=True)
            path = self.path(name)
            backup = self.backup(path)
            data = dict(name=name, box_type=self.box_type, schema_version=2,
                        saved_at=datetime.now(timezone.utc).isoformat(timespec='microseconds'), config=config)
            temp = self.directory / f'.{uuid.uuid4().hex}.tmp'
            try:
                temp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
                temp.replace(path)
            finally:
                temp.unlink(missing_ok=True)
            return dict(name=name, saved_at=data['saved_at'], backup=backup)

    def delete(self, name):
        with LOCK:
            path = self.path(name)
            if not path.exists():
                raise FileNotFoundError('配置不存在')
            backup = self.backup(path)
            path.unlink()
            return dict(ok=True, backup=backup)
