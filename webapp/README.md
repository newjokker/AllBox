# ESP32 壳体在线生成器

网页使用项目根目录的统一入口 `esp32_shell.scad` 和建模内核 `esp32_shell_core.scad`。各块 ESP32 开发板不再复制 SCAD 脚本，差异参数保存在 `webapp/configs/*.json`，可在网页的“选择配置”中加载后预览、调整和下载 STL。

仓库自带以下迁移后的板型配置：

- ESP32-C3 WeAct
- ESP32-C6 WeAct
- ESP32 WeAct
- ESP32-S3 正点原子

配置支持多 Type-C、侧面/顶面/底面矩形开口、可关闭的排针槽、按压板、固定柱、卡扣阵列和蜂窝参数。页面将每种结构分成独立折叠区。卡扣自动生成会先扣除两端圆角安全区，只保留能完整放下的 5 mm 凹凸条；如果空间不足就减少一条，再将剩余空间均匀分配，保证相邻净距不小于 4 mm。新建配置默认不生成这些附加结构，需要时再逐项开启或添加；旧配置中已有的排针参数会继续按开启处理。基础尺寸使用 `PCB 宽度/长度 + PCB 板边余量` 自动计算盒内净尺寸，预设余量为 0.5 mm。按压板和固定柱的纵向位置使用其中心到 front 前端内壁的距离；旧配置的中心坐标 `y` 会自动换算。

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

配置文件保存在 `webapp/configs/`，每个板子对应一个 JSON。接口既能按安全化后的文件名查找，也能按 JSON 内的显示名称加载，因此预置配置可以使用稳定的英文文件名。

生成结果按“SCAD 源码哈希 + 参数”缓存在 `/tmp/esp32-shell-stl-cache`，并使用单一渲染锁避免 OpenSCAD 并发占满机器。
