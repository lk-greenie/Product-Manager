# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 项目概览

这是一个 Windows 桌面端产品进销存管理系统，使用 Qt 6、C++、Qt Quick/QML 和 MySQL。项目由 qmake 管理；`qmlProductManager.pro` 是唯一的构建清单。C++ 提供认证、数据库操作和 Qt SQL 模型，QML 负责窗口、导航、表格和业务表单。

当前仓库没有自动化测试工程、单测试命令或独立 lint 配置。历史 README 仍是未填写的 Gitee 模板，不能作为构建或架构依据。

## 构建与运行

已生成的 Qt Creator 构建信息使用 Qt 6.8.3、MinGW 13.1 64 位和 C++17。以下命令从 Git Bash 执行；如果 Qt 安装位置不同，请替换 `QMAKE` 和 `MINGW_MAKE`。

```bash
QMAKE="/e/Qt/6.8.3/mingw_64/bin/qmake.exe"
MINGW_MAKE="/e/Qt/Tools/mingw1310_64/bin/mingw32-make.exe"
BUILD_DIR="build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug"

mkdir -p "$BUILD_DIR"
"$QMAKE" -o "$BUILD_DIR/Makefile" qmlProductManager.pro -spec win32-g++ "CONFIG+=debug" "CONFIG+=qml_debug"
"$MINGW_MAKE" -C "$BUILD_DIR" -j4
```

运行 Debug 版本：

```bash
./build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug/debug/qmlProductManager.exe
```

清理构建产物：

```bash
"$MINGW_MAKE" -C "$BUILD_DIR" clean
```

Release 构建使用独立目录，避免与 Debug Makefile 混用：

```bash
RELEASE_DIR="build/Desktop_Qt_6_8_3_MinGW_64_bit-Release"
mkdir -p "$RELEASE_DIR"
"$QMAKE" -o "$RELEASE_DIR/Makefile" qmlProductManager.pro -spec win32-g++ "CONFIG+=release"
"$MINGW_MAKE" -C "$RELEASE_DIR" -j4
```

修改 `.pro` 文件或 `qml.qrc` 后应重新运行 qmake，再构建。项目没有测试目标，因此目前无法运行全部测试或单个测试；最低验证方式是完成 Debug 构建，并在可用的 MySQL 环境中启动应用、手动走通受影响流程。

## 运行前提

Qt 安装必须包含 Quick、QML、Widgets、SQL 模块和 MySQL SQL 驱动（`QMYSQL`）。程序依赖本机 `127.0.0.1:3306` 上的两个 MySQL 数据库：

- `user_management`：认证数据库，连接和登录/注册逻辑位于 `enter.cpp`。代码会在缺少 `users` 表时创建基础表，但登录还会读取 `permission` 列，因此实际 schema 必须包含该列。
- `ecjtu_market`：业务数据库，连接和模型初始化位于 `tabledisplay.cpp`。代码假定 `category`、`stock`、`record`、`expense`、`income` 已存在，不负责创建这些表。

连接参数目前直接写在两个 C++ 文件中。数据库不可用时，认证入口显示错误页；业务模型只有在业务数据库成功连接后才可使用。

## 架构与数据流

### 启动和 QML 桥接

`main.cpp` 创建 `QApplication` 和单个 `QQmlApplicationEngine`，构造两个长生命周期后端对象，并以 QML 上下文属性暴露：

- `loginManager` 是 `Enter`，提供 `registerUser()`、`loginUser()`、`getLastError()` 和权限属性 `per`。
- `TableDisplay` 是 `TableDisplay`，提供库存/交易方法及多个 Qt SQL 模型。

引擎首先加载资源中的 `qml/Login&Register/Enter.qml`。登录页通过 `loginManager` 验证用户；成功后再次打开业务数据库、调用 `TableDisplay.init_Cat()`，关闭登录窗并动态创建 `qrc:/qml/MainMenu.qml`。因此修改启动、登录或主窗口创建逻辑时，需要同时检查 `main.cpp`、`Enter.qml` 和 `LoginPage.qml`。

`TableDisplay` 在 C++ 构造时已经调用一次 `openDatabase()`，登录成功后 QML 又调用一次。变更连接生命周期时要同时处理这两个入口以及命名连接 `ecjtu_market_connection`。

### 业务后端和模型

`tabledisplay.cpp` 集中承担数据访问层职责：

- `catModel`、`stockModel`、`checkModel`、`expenseModel`、`incomeModel`、`cnameModel` 映射业务表或查询。
- `proxyModel` 至 `proxyModel3` 为库存、总交易、支出、收入页面提供按商品名搜索。
- `Q_INVOKABLE` 方法由 QML 直接调用，覆盖分类维护、入库、出库、售价/阈值设置、分类筛选、排序和汇总。
- 入库会更新 `stock`，并通过 `addCheck()` 写入 `record` 与 `expense`；出库会扣减 `stock`，并写入 `record` 与 `income`。
- 写操作后依赖 `model->select()` 刷新 QML 表格。新增或修改写操作时，需要刷新所有受影响的源模型；代理模型会随源模型更新。

QML 直接依赖模型字段顺序、字段名和 C++ 设置的表头。例如表格 delegate 按列索引格式化日期，筛选器用字符串标志 `stock`、`check`、`expense`、`income` 选择模型。修改 SQL 查询列、表结构或这些标志时必须同步相关 QML 页面。

### QML 页面组织

`qml/MainMenu.qml` 是业务壳层：左侧导航控制右侧 `StackLayout`，其索引依次对应库存、总交易、支出、收入、成本、销售额、利润和 AI 页面。调整导航项时必须同步 `ListElement.index` 和 `StackLayout` 子项顺序。

页面按领域分组：

- `qml/StockManagement/`：库存表及分类、入库、出库、售价、库存上下限弹窗。
- `qml/CheckRecords/`：总交易、支出和收入表格。
- `qml/DataVisualization/`：成本筛选界面及图表组件；销售额、利润和部分图表目前仍是占位实现。
- `qml/AIAssistant/` 与 `qml/Person/`：目前也是空白或占位页面。
- `qml/Login&Register/`：登录、注册和数据库连接错误页。登录页使用 `Qt.labs.settings` 的 `user_config.ini` 保存“记住密码”状态。

库存页面根据 `loginManager.per` 在 QML 中控制操作权限：分类/入出库要求 `per < 3`，售价和阈值设置要求 `per < 2`。权限含义依赖 `users.permission` 的数值约定。

## 资源与文件联动

所有运行时 QML 和图标都嵌入 `qml.qrc`。新增、移动或重命名 QML/图片时必须：

1. 更新 `qml.qrc`；
2. 更新静态 import、`Qt.createComponent()` 或 `qrc:/...` 路径；
3. 重新运行 qmake 后构建。

QML 中既有完整资源路径（如 `qrc:/qml/MainMenu.qml`），也有相对动态路径（如库存目录内的 `AddCat.qml`、`In.qml`）。相对路径依赖调用页面所在目录，移动页面时尤其容易失效。目录名 `Login&Register` 在 XML 中写作 `Login&amp;Register`，在 C++/QML URL 中仍使用字面量 `&`。

## 当前仓库注意事项

工作树正在进行大规模 QML 目录重组；不要恢复或覆盖已有的删除、移动和修改。根 `.gitignore` 目前仍包含未解决的 Git 冲突标记，且 `qml/Login&Register/user_config.ini` 是本机运行状态文件而非源码。处理构建产物或本地配置前先核对当前工作树状态。
