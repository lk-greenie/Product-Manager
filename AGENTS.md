# AGENTS.md

本文件是维护本仓库时的项目约定和事实说明。回答问题、编写文档和注释默认使用简体中文。修改代码前先查看当前工作树；不要覆盖用户已有的未提交修改。

## 项目概览

这是一个 Windows 桌面端产品进销存管理系统，技术栈为 Qt 6、C++17、Qt Quick/QML、Qt SQL、Qt Charts、Qt Network 和 MySQL。项目使用 qmake，`qmlProductManager.pro` 是唯一的构建清单。

- `src/app/`：程序入口和运行时配置加载。
- `src/backend/auth/`：用户注册、登录、会话和个人资料更新。
- `src/backend/inventory/`：业务数据库连接、Qt SQL 模型、库存/交易操作、筛选和图表查询。
- `src/backend/ai/`：DeepSeek OpenAI 兼容接口、AI 会话/消息持久化和数据库查询工具调用。
- `qml/`：登录注册、主窗口导航、库存、交易记录、数据可视化、AI 助手和个人资料页面。
- `database/`：完整数据库结构脚本和测试数据重置脚本。
- `config/app.ini.example`：运行配置模板；真实的 `config/app.ini` 不提交到 Git。

仓库没有自动化测试工程、测试目标或独立 lint 配置。最低验证方式是完成 Debug 构建，并在可用的 MySQL 和 AI 配置下手动走通受影响流程。

## 构建与运行

当前 Qt Creator 配置使用 Qt 6.8.3、MinGW 13.1 64 位和 C++17。以下命令从 Git Bash 执行；Qt 安装位置不同则替换路径。

```bash
export PATH="/e/Qt/Tools/mingw1310_64/bin:$PATH"
QMAKE="/e/Qt/6.8.3/mingw_64/bin/qmake.exe"
MINGW_MAKE="/e/Qt/Tools/mingw1310_64/bin/mingw32-make.exe"
BUILD_DIR="build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug"

mkdir -p "$BUILD_DIR"
"$QMAKE" -o "$BUILD_DIR/Makefile" qmlProductManager.pro -spec win32-g++ "CONFIG+=debug" "CONFIG+=qml_debug"
"$MINGW_MAKE" -f "$BUILD_DIR/Makefile" -j1
```

Debug 可执行文件通常位于：

```bash
./build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug/debug/qmlProductManager.exe
```

Release 构建使用独立目录，避免与 Debug Makefile 混用：

```bash
RELEASE_DIR="build/Desktop_Qt_6_8_3_MinGW_64_bit-Release"
mkdir -p "$RELEASE_DIR"
"$QMAKE" -o "$RELEASE_DIR/Makefile" qmlProductManager.pro -spec win32-g++ "CONFIG+=release"
"$MINGW_MAKE" -f "$RELEASE_DIR/Makefile" -j1
```

修改 `qmlProductManager.pro` 或 `qml.qrc` 后必须重新运行 qmake。`.pro` 中的 Windows post-link 规则会把 `config/` 目录复制到可执行文件同级目录，因此 Qt Creator 影子构建目录中也必须存在 `config/app.ini`。

## 运行配置

程序启动时由 `AppConfig` 从可执行文件同级的 `config/app.ini` 读取配置；也可以使用环境变量 `QML_PRODUCT_MANAGER_CONFIG` 指定 INI 文件的绝对路径。首次运行：

```powershell
New-Item -ItemType Directory -Force .\config
Copy-Item .\config\app.ini.example .\config\app.ini
```

主要配置节：

- `[application]`：应用名称、组织信息、Qt Quick Controls 样式、图形渲染后端、图标、QML 启动入口和日志文件路径。
- `[userDatabase]`：用户认证及 AI 会话数据库连接，默认数据库名为 `user_management`。
- `[businessDatabase]`：分类、库存、交易、收支和图表查询数据库连接，默认数据库名为 `warehouse`。程序启动时会自动创建数据库及所需表。
- `[ai]`：DeepSeek API 密钥、OpenAI 兼容 Chat Completions 地址、模型、流式开关和系统提示词。当前工具调用流程固定使用非流式请求，模板中的 `stream` 应保持为 `false`。

不要把数据库密码、DeepSeek 密钥或真实 `app.ini` 提交到 Git。默认日志文件为可执行文件同级的 `qmlProductManager.log`，也可通过 `[application]` 的 `logFile` 修改。

`graphicsApi` 默认建议使用 `Software`，可避免无 GPU、远程桌面或 OpenGL 初始化失败导致图表空白；确认运行环境稳定支持 OpenGL 后才改为 `OpenGL`。

## 数据库

使用具备建库权限的 MySQL 用户执行 `database/schema.sql`：

```bash
mysql -u root -p < database/schema.sql
```

脚本创建以下结构：

- `user_management.users`：账号、SHA-256 密码摘要、邮箱和权限值（`1` 店主、`2` 店员、`3` 顾客访客）。新注册账号默认为 `3`。
- `user_management.ai_conversations`、`ai_messages`：按用户隔离的 AI 会话和消息记录；`DeepSeekClient` 会在需要时幂等确认表存在。
- `warehouse.category`、`stock`、`record`、`expense`、`income`：分类、库存、总交易、支出和收入数据，并包含外键、检查约束及索引。

测试环境可使用以下脚本重置并导入示例数据：

```powershell
python database/reset_db.py
```

该脚本会删除两个数据库中的现有测试数据并重建演示账号，必须先完成 schema 初始化、填写 `config/app.ini` 密码并安装 `pymysql`。不要在生产数据上执行。

## 启动流程与后端桥接

`src/app/main.cpp` 创建 `QApplication`、加载 `AppConfig`、安装文件日志处理器，并构造三个长生命周期后端对象：

- `loginManager`：`Enter`，暴露注册、登录、会话清理、资料更新、用户列表和角色修改及 `per/userId/username/email/roleName` 属性。店主可将其他账号设置为店员或顾客访客，不能修改自己的角色。
- `TableDisplay`：库存和交易后端，暴露多个 `QSqlRelationalTableModel`、代理模型和 `Q_INVOKABLE` 业务方法。
- `aiManager`：`DeepSeekClient`，暴露会话模型、消息模型、会话管理和发送消息方法；通过 `setDataProvider()` 查询当前业务数据。

引擎默认加载 `qrc:/qml/Login&Register/Enter.qml`。登录成功后，`LoginPage.qml` 依次调用 `TableDisplay.openDatabase()`、`TableDisplay.init_Cat()` 和 `TableDisplay.setCurrentPermission(loginManager.per)`，然后进入 `qrc:/qml/MainMenu.qml`。无边框登录窗口仅允许拖动顶部标题栏空白区域，内容区和右上角窗口控制按钮不参与拖动。修改启动入口、登录流程或上下文属性时，应同时检查 `main.cpp`、`Enter.qml`、`LoginPage.qml` 和主窗口组件。

用户数据库连接名为 `user_management_connection`，业务数据库连接名为 `warehouse_connection`。两个后端构造时会尝试连接，业务库登录成功后还会再次调用 `openDatabase()`；该调用必须保持幂等，不能重建已经暴露给 QML 的模型指针。

## 业务后端与模型

`TableDisplay` 的实现已拆分为四个源文件：

- `tabledisplay_db_models.cpp`：业务数据库连接、模型创建、模型刷新和代理模型。
- `tabledisplay_inventory.cpp`：入库、出库、售价、库存上下限及权限控制。
- `tabledisplay_query.cpp`：分类、商品、记录筛选、汇总、排序和图表数据查询。
- `tabledisplay_context.cpp`：提供给 AI 工具调用的分类、库存、交易和财务摘要。

QML 依赖以下模型属性和列顺序：`catModel`、`stockModel`、`checkModel`、`expenseModel`、`incomeModel`、`cnameModel`，以及 `proxyModel` 至 `proxyModel3`。库存关系模型的列顺序为 `cat_name,cat_id,cname,bid,m_date,e_date,price,sum,up_sum,down_sum`，其中 `cat_id` 为内部关联字段、由 `DataTable` 隐藏；调整 SQL 查询列、字段名或表头时必须同步 `DataTable.qml`、`DisplayPage.qml` 和相关 delegate。

写操作完成后必须刷新所有受影响的源模型；代理模型依赖源模型更新。入库会增加 `stock` 并写入 `record`、`expense`；出库会扣减 `stock` 并写入 `record`、`income`。筛选标志目前使用 `stock`、`check`、`expense`、`income`，修改这些字符串时必须同步 QML 调用方。

## QML 页面与权限

`qml/MainMenu.qml` 组合 `MainMenu/SideNavigation.qml`、`MainMenu/MainContentStack.qml` 和 `MainMenu/ProfilePopup.qml`。导航使用路由字符串而非固定页面索引：`stock`、`records.all`、`records.expense`、`records.income`、`visual.profit`、`visual.cost`、`visual.sales`、`assistant`。新增或调整路由时必须同步侧边栏、`BackendContract.qml` 和内容栈映射。

页面目录：

- `qml/StockManagement/`：库存展示、分类、入库、出库、售价和上下限设置。
- `qml/CheckRecords/`：总交易、支出和收入记录。
- `qml/DataVisualization/`：成本、销售额、利润筛选及饼图、柱图、折线图组件。
- `qml/AIAssistant/`：按账号隔离的 DeepSeek 会话界面。
- `qml/Person/`：个人资料与退出登录。
- `qml/Components/`、`qml/StockManagement/Components/`、`qml/Services/`：共享控件、后端权限契约和业务表单组件。

权限边界由 `qml/Services/BackendContract.qml` 和 `TableDisplay` 双重控制：

- 店主（`1`）：全部页面和全部库存维护操作。
- 店员（`2`）：库存入库/出库、交易记录和数据可视化；不能新增分类、修改售价或库存上下限。
- 顾客访客（`3`）：只能查看公开库存和 AI；库存页隐藏进价、上下限、预警/过期状态色，且不能查看交易、收支和可视化数据。

AI 工具调用也遵守当前权限：访客只能获得公开库存信息，店主和店员可查询完整库存、交易和财务摘要。

## 资源与文件联动

所有运行时 QML、共享 `qmldir` 和图标都通过 `qml.qrc` 嵌入。新增、移动或重命名 QML/图片时必须：

1. 更新 `qml.qrc`；
2. 更新静态 import、`Qt.createComponent()`、`qrc:/...` 路径或相对组件路径；
3. 重新运行 qmake 后构建。

资源路径中的目录名 `Login&Register` 在 XML 中写为 `Login&amp;Register`，而 C++/QML URL 使用字面量 `&`。相对路径依赖调用页面所在目录，移动库存弹窗或共享组件时尤其要检查。

## 修改前检查

开始工作前先运行 `git status --short`，确认是否存在用户未提交的移动、删除或修改。不要恢复这些变更。检查构建产物、本机配置和日志时注意：`build/`、`config/app.ini`、`qmlProductManager.pro.user`、`user_config.ini` 和日志文件均可能是本机状态，不应当作为源码重写。网络受限时，优先使用本地依赖和已有配置；确需访问外网时可按用户环境尝试代理端口 `65532`。
