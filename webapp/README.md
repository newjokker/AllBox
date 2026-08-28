# ESP32-C3 WeAct 壳体在线生成器

网页直接调用项目根目录的 `esp32_c3_weact_shell.scad` 和 `esp32_shell_core.scad`，支持在线调整常用结构参数、添加/删除多个 Type-C 开口、扩展出口和按压板，查看后端实际导出的 STL，并下载底盒、上盖或整套模型。每个按压板都能独立设置 X/Y 位置、弹片方向、触点长度和弹片长度。

## 本机启动

```bash
cd /Volumes/Jokker/Code/AllBox
python3 -m venv .venv
.venv/bin/pip install -r webapp/requirements.txt
OPENSCAD_BIN=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD .venv/bin/python webapp/app.py
```

浏览器打开 <http://127.0.0.1:55505>。同一局域网设备可使用这台电脑的 IP 和端口 `55505` 访问。

也可以直接运行：

```bash
./webapp/start.sh
```

## Linux 部署

安装 OpenSCAD、Python 3 和依赖后，还需要让 OpenSCAD 能找到 BOSL2。服务器没有全局 BOSL2 时，可放到项目内：

```bash
cd /opt/AllBox
mkdir -p third_party
git clone --depth 1 https://github.com/BelfrySCAD/BOSL2.git third_party/BOSL2
```

应用会自动把项目内的 `third_party` 加入 `OPENSCADPATH`。随后按实际目录修改 `esp32-shell-web.service` 的 `WorkingDirectory`、`Environment` 与 `ExecStart`，再交给 systemd 启动。服务文件使用单 Gunicorn worker + 多线程，确保 OpenSCAD 渲染锁在所有请求之间生效。生产环境建议在前面使用 Nginx/Caddy 配置 HTTPS，并限制请求频率。

接口：

- `GET /health`：服务和模型源状态。
- `GET /api/config`：当前模型源与 OpenSCAD 路径。
- `GET|POST /api/shell-stl`：生成或下载 STL；网页使用 JSON POST 预览，GET 查询参数下载。
- `GET /api/configs`：列出已保存的板子配置。
- `POST /api/configs`：保存当前参数为一个命名配置（JSON 体 `{"name": "...", "config": {...}}`）。
- `GET /api/configs/<name>`：加载指定配置，回填表单后可重新预览/打印。
- `DELETE /api/configs/<name>`：删除指定配置。

配置文件保存为 `webapp/configs/<名字>.json`（名字会做文件名安全化处理），每个板子对应一个配置文件，可按需导入之前的配置再打印。

生成结果按“SCAD 源码哈希 + 参数”缓存在 `/tmp/esp32-shell-stl-cache`，并使用单一渲染锁避免 OpenSCAD 并发占满机器。
