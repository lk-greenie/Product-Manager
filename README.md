# qmlProductManager

基于 Qt 6、C++17、Qt Quick/QML 和 MySQL 的 Windows 桌面进销存管理系统。项目包含账号与角色管理、分类与库存维护、入库/出库记录、收入支出统计、数据可视化，以及可查询当前业务数据的 DeepSeek AI 助手。

## 主要功能

- 用户注册、登录、记住登录状态和个人资料维护。
- 店主、店员、顾客访客三级权限控制。
- 商品分类、库存、售价、库存上下限和预警状态管理。
- 入库、出库、收入、支出及完整交易记录查询。
- 成本、销售额、利润的饼图、柱图和折线图分析。
- 按用户隔离的 AI 会话和消息记录。
- 使用 Windows DPAPI 加密数据库服务器配置与记住登录凭据。
- 支持手动连接和断开数据库，手动断开后不会被业务查询自动重连。

## 权限说明

| 角色 | 权限值 | 可用功能 |
| --- | ---: | --- |
| 店主 | 1 | 全部页面、分类维护、库存维护、用户角色管理和完整业务数据查询 |
| 店员 | 2 | 入库、出库、交易记录、数据可视化和完整业务数据查询 |
| 顾客访客 | 3 | 公开库存和 AI 助手，不显示进价、库存阈值、交易及财务数据 |

权限同时由 QML 页面和 C++ 后端校验，不能仅通过显示或隐藏按钮绕过。

## 技术栈

- Qt 6.8.3、Qt Quick/QML、Qt Quick Controls
- Qt SQL、Qt Charts、Qt Network、Qt Widgets
- C++17、qmake、MinGW 13.1 64 位
- MySQL，Qt `QMYSQL` 驱动
- DeepSeek OpenAI 兼容 Chat Completions 接口

## 目录结构

```text
qmlProductManager/
├─ config/                 运行配置模板；真实配置不提交
├─ database/               数据库结构、清理及测试数据脚本
├─ images/                 应用图标和图片资源
├─ qml/                    登录、主界面、库存、图表及 AI 页面
├─ scripts/                Release 可执行程序打包脚本
├─ src/app/                程序入口、配置和服务器连接管理
├─ src/backend/auth/       登录、注册、会话与角色管理
├─ src/backend/inventory/  库存、交易、筛选、图表及 AI 数据上下文
├─ src/backend/ai/         DeepSeek 客户端和 AI 会话持久化
├─ tests/                  Qt Test 自动化测试
├─ qml.qrc                 QML 与图片资源清单
└─ qmlProductManager.pro   qmake 构建清单
```

## 分支约定

| 分支 | 职责 |
| --- | --- |
| `master` | 已验证、可构建的稳定源码 |
| `dev` | 日常开发源码；V1.0 发布时与 `master` 保持一致 |
| `release` | 仅保存可直接下载的 Windows 运行包、依赖、配置模板和发布说明 |

远程仓库：

- GitHub：`git@github.com:lk-greenie/Product-Manager.git`
- Gitee：`git@gitee.com:lkonly/database-course-design.git`

## 环境要求

### 从源码构建

- Windows 10/11 64 位
- Qt 6.8.3 MinGW 64 位
- MinGW 13.1 64 位
- MySQL Server 8.x 或 9.x
- Qt 安装中包含 `QMYSQL` 驱动
- 可选：Python 3 与 `pymysql`，用于重置演示数据

### 运行 Release 包

- Windows 10/11 64 位
- 可访问的 MySQL 服务器
- 如果系统缺少 Microsoft Visual C++ 2015-2022 x64 Runtime，可运行发布包 `prerequisites/VC_redist.x64.exe`
- AI 助手需要自行配置有效的 DeepSeek API 密钥；其他功能不依赖 AI 密钥

## 配置文件

程序默认从可执行文件同级的 `config/app.ini` 加载配置，也可以通过环境变量 `QML_PRODUCT_MANAGER_CONFIG` 指定绝对路径。

首次从源码运行时执行：

```powershell
New-Item -ItemType Directory -Force .\config
Copy-Item .\config\app.ini.example .\config\app.ini
```

数据库地址、端口、账号、密码和数据库名不以明文写入仓库。请在登录窗口或“我的”页面中生成或导入 `config/database_server_config.enc`。该文件使用 Windows DPAPI 加密，只能由生成它的 Windows 用户解密。

以下文件包含本机状态或敏感信息，已由 `.gitignore` 排除：

```text
config/app.ini
config/database_server_config.enc
config/login_credentials.enc
config/login.ini
*.log
```

不要提交真实数据库密码、DeepSeek API 密钥或上述加密文件。

## 初始化数据库

使用具备建库权限的 MySQL 用户执行：

```powershell
mysql -u root -p < database/schema.sql
```

脚本将创建：

- `user_management`：用户、AI 会话和 AI 消息。
- `warehouse`：分类、库存、总交易、支出和收入。

测试环境可重置并导入示例数据：

```powershell
mysql -u root -p < database/reset_inventory.sql
```

`reset_inventory.sql` 会删除两个数据库中的现有数据、复位自增主键并写入演示数据。不要对生产数据库执行该脚本。

## Debug 构建

以下命令从项目根目录执行。构建命令必须在生成 Makefile 的目录中运行，避免 qmake 子 Makefile 的相对路径解析错误。

```powershell
$env:PATH = "E:\Qt\Tools\mingw1310_64\bin;$env:PATH"
$BuildDir = "build\Desktop_Qt_6_8_3_MinGW_64_bit-Debug"

New-Item -ItemType Directory -Force $BuildDir | Out-Null
Push-Location $BuildDir
& "E:\Qt\6.8.3\mingw_64\bin\qmake.exe" `
    -o Makefile "..\..\qmlProductManager.pro" `
    -spec win32-g++ "CONFIG+=debug" "CONFIG+=qml_debug"
& "E:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe" -f Makefile -j1
Pop-Location
```

生成的程序位于：

```text
build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug/debug/qmlProductManager.exe
```

## 自动化测试

当前 Qt Test 覆盖数据库服务器配置和记住登录凭据的 DPAPI 加密存储。

```powershell
$env:PATH = "E:\Qt\Tools\mingw1310_64\bin;$env:PATH"
$TestBuild = "tests\build-server-connection-settings"

New-Item -ItemType Directory -Force $TestBuild | Out-Null
Push-Location $TestBuild
& "E:\Qt\6.8.3\mingw_64\bin\qmake.exe" `
    -o Makefile "..\server_connection_settings_test.pro" `
    -spec win32-g++ "CONFIG+=debug"
& "E:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe" -f Makefile -j1
& ".\debug\server_connection_settings_test.exe" -o -,txt
Pop-Location
```

## 构建 Release 运行包

仓库提供 `scripts/package-release.ps1`，用于编译程序、调用 `windeployqt`、收集 MySQL/OpenSSL 依赖、生成脱敏配置和 SHA-256 清单。

```powershell
.\scripts\package-release.ps1 `
    -Version "1.0" `
    -QtRoot "E:\Qt\6.8.3\mingw_64" `
    -MinGwRoot "E:\Qt\Tools\mingw1310_64" `
    -MySqlRoot "C:\Program Files\MySQL\MySQL Server 9.3"
```

输出目录：

```text
build/release-package/ProductManager-v1.0-win64/
```

脚本不会复制本机的 `config/app.ini`、数据库加密配置、登录凭据或日志。

## Release 包使用

1. 下载 `release` 分支 ZIP 并解压。
2. 必要时运行 `prerequisites/VC_redist.x64.exe`。
3. 在 MySQL 中执行 `database/schema.sql`。
4. 双击 `qmlProductManager.exe`。
5. 在登录窗口设置中生成或导入数据库服务器加密配置。
6. 如需 AI 助手，在 `config/app.ini` 中填写 DeepSeek API 密钥。

默认使用 `Software` 图形后端，以兼容无独立 GPU、远程桌面和部分虚拟机环境。

## 常见问题

### 提示 QMYSQL 驱动不可用

确认运行目录包含：

```text
sqldrivers/qsqlmysql.dll
libmysql.dll
libssl-3-x64.dll
libcrypto-3-x64.dll
```

### 程序无法启动或提示缺少运行库

先运行 `prerequisites/VC_redist.x64.exe`，然后重新启动程序。

### 图表空白或图形初始化失败

保持 `config/app.ini` 中的 `graphicsApi=Software`。只有确认设备稳定支持 OpenGL 时才改为 `OpenGL`。

### 查看运行日志

默认日志文件为可执行程序同级的 `qmlProductManager.log`。日志和本机配置不应提交到仓库。

## 许可证

本项目使用 [GNU Lesser General Public License v3.0](LICENSE)。发布和再分发时请保留许可证文件，并遵守 LGPL-3.0 的相应条款。
