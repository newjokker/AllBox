# ESP32 壳体在线生成器

网页使用项目根目录的统一入口 `esp32_shell.scad` 和建模内核 `esp32_shell_core.scad`。各块 ESP32 开发板不再复制 SCAD 脚本，差异参数保存在 `data/box-configs/esp32-shell/*.json`，可在网页的“选择配置”中加载后预览、调整和下载 STL。

仓库自带以下迁移后的板型配置：

- ESP32-C3 WeAct
- ESP32-C6 WeAct
- ESP32 WeAct
- ESP32-S3 正点原子

配置支持多 Type-C、侧面/顶面/底面矩形开口、可关闭的排针槽、按压板、固定柱、卡扣阵列和蜂窝参数。新建配置默认不生成这些附加结构，需要时再逐项开启或添加；旧配置中已有的排针参数会继续按开启处理。基础尺寸使用 `PCB 宽度/长度 + PCB 板边余量` 自动计算盒内净尺寸，预设余量为 0.5 mm。按压板和固定柱的纵向位置使用其中心到 front 前端内壁的距离；旧配置的中心坐标 `y` 会自动换算。

## 本机启动

```bash
cd /Volumes/Jokker/Code/AllBox
python3 -m venv .venv
.venv/bin/pip install -r webapp/requirements.txt
.venv/bin/python webapp/migrate_configs.py
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

配置文件保存在 `data/box-configs/esp32-shell/`，每个板子对应一个 JSON。接口既能按安全化后的文件名查找，也能按 JSON 内的显示名称加载，因此预置配置可以使用稳定的英文文件名。

生成结果按“SCAD 源码哈希 + 参数”缓存在 `/tmp/esp32-shell-stl-cache`，并使用单一渲染锁避免 OpenSCAD 并发占满机器。

## PCB 螺丝柱盒

访问 `/pcb` 使用 PCB 螺丝柱盒生成器，原 ESP32 页面仍在 `/`。两者共用现有 OpenSCAD 服务和渲染锁；PCB 模型使用项目根目录 `pcb_box.scad`，表单默认值直接读取该文件。

- 仅保留四边“最外侧孔中心到盒子内壁距离”，不再分板边距离与板外预留。支持矩形四孔或自定义坐标。
- 盒内尺寸 = 孔位跨度 + 两侧内壁距离；盒外尺寸再加两倍壁厚。俯视图显示孔位范围和内壁距离，不推测 PCB 板边。
- 自动上盖高度 = 底厚 + 板下净空 + 板厚 + 板上器件高度 + 顶部余量 + 顶厚 − 下盒高度。手动模式仍检查器件净空和唇边空间。
- 上下柱夹板间距 = 板厚 + 夹板装配余量。下盒高度不含突出的定位唇边。
- 所有开孔统一在“额外开孔”中添加、修改或删除。默认列表保留前侧 8 × 4 mm 矩形孔，横向偏移 −20 mm、下沿高度 2 mm；横向填 0 即居中。
- 网页额外侧面孔使用孔下沿高度，传给 SCAD 时自动转换为中心高度；顶底面使用中心 X/Y。
- 可查看尺寸俯视图、生成真实 3D 模型、分别下载底盒/上盖 STL，以及下载包含当前参数的独立 SCAD。
- STL/SCAD 下载固定使用打印摆放，避免装配视图中的零件重叠。3D 预览仍支持装配、打开和平铺。
- “保存配置 / 选择配置”使用云端命名配置，支持跨设备加载。未保存的修改在当前浏览器暂存，JSON 导入导出继续保留。
- PCB 配置位于 `data/box-configs/pcb-screw-box/`，与 ESP32 配置完全分开；同名覆盖时在各自 `history/` 保存上一版。
- v1 浏览器草稿/JSON 导入时自动迁移：孔到内壁 = 原孔到板边 + 原板外间隙；前侧专用孔合并到额外开孔数组。迁移保留零值、开孔总开关和模型几何，导出使用 v2 格式。
- 服务限制自定义孔位和开孔各 32 项，检查非有限数字、几何越界、柱脚碰撞、开孔与柱脚区域重叠；顶底开孔采用保守的矩形范围检查。

接口：`GET /api/pcb/config`、`POST /api/pcb/validate`、`POST /api/pcb/stl`、`POST /api/pcb/scad`。POST 体为参数对象。下载使用 `?download=1`。

部署继续运行项目根目录的 `./webapp/deploy-to-cloud.sh`，脚本同时传送 `pcb_box.scad`。部署前会备份服务器代码与运行时配置，且不覆盖服务器已有 ESP32 配置。

检查：`python -m unittest discover -s webapp -p 'test_*.py'`；前端语法检查：`node --check webapp/static/pcb.js`。

## 配置目录与迁移

运行时数据与网页代码分开，服务器根目录为 `/opt/AllBox`：

```text
data/box-configs/esp32-shell/       # ESP32 壳体配置与 history/
data/box-configs/pcb-screw-box/     # PCB 螺丝柱盒配置与 history/
data/config-backups/              # 部署时的全部配置快照
data/migration-history/           # 原 webapp/configs 目录的完整归档
webapp/presets/esp32-shell/        # 随项目发布的预置配置
```

`migrate_configs.py` 在本地启动脚本和部署脚本中执行：逐文件校验并迁移旧 ESP32 配置及历史，冲突时报错并保留原数据。预置配置只补充缺失文件。部署时先停止服务写入，再备份和迁移，完成后恢复服务；运行时配置目录不参与 rsync 覆盖。之前的 `/opt/AllBox/config-history/` 历史备份仍保留。

ESP32 的 `ESP32_SHELL_CONFIG_DIR` 环境变量仍可覆盖默认目录；PCB 可通过 `PCB_BOX_CONFIG_DIR` 设置独立目录。

PCB 云端接口：`GET|POST /api/pcb/configs`、`GET|DELETE /api/pcb/configs/<name>`。保存体为 `{"name":"配置名","config":{...参数}}`。写入前校验参数，保存采用原子替换，覆盖和删除均保留历史文件。
