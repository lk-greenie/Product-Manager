# qmlProductManager V1.0 Windows 运行包

本分支只保存已经打包完成的 Windows 64 位程序及运行依赖，不包含开发源码。下载本分支 ZIP 并解压后，可以直接启动 `qmlProductManager.exe`。

## 首次运行

1. 准备可访问的 MySQL 服务器。
2. 使用 MySQL 客户端执行 `database/schema.sql`。
3. 如果程序提示缺少 Microsoft Visual C++ 运行库，执行 `prerequisites/VC_redist.x64.exe`。
4. 双击 `qmlProductManager.exe`。
5. 在登录窗口右上角打开设置，生成或导入数据库服务器加密配置。
6. 如需使用 AI 助手，在 `config/app.ini` 中填写自己的 DeepSeek API 密钥。

## 目录说明

- `qmlProductManager.exe`：主程序。
- `config/app.ini`：脱敏的运行配置，可填写自己的 AI 密钥。
- `database/schema.sql`：数据库结构初始化脚本。
- `sqldrivers/qsqlmysql.dll`：Qt MySQL 数据库驱动。
- `libmysql.dll`、`libssl-3-x64.dll`、`libcrypto-3-x64.dll`：MySQL 客户端运行依赖。
- `prerequisites/VC_redist.x64.exe`：Microsoft Visual C++ 2015-2022 x64 Runtime 安装程序。
- `SOURCE_COMMIT.txt`：本运行包对应的源码提交。
- `SHA256SUMS.txt`：发布文件完整性校验值。

## 配置安全

发布包不包含数据库密码、真实 DeepSeek API 密钥、登录凭据或开发者本机配置。数据库配置与记住登录状态会使用 Windows DPAPI 加密，并保存在 `config` 目录中。

DPAPI 文件只能由生成它的 Windows 用户解密。将程序复制给其他用户时，请让对方重新生成数据库服务器配置，不要共享自己的 `.enc` 文件。

## 运行要求

- Windows 10/11 64 位。
- 可访问的 MySQL Server 8.x 或 9.x。
- 默认使用软件图形后端，无需安装 Qt 或 MinGW。
- AI 助手是可选功能，需要用户自行提供 DeepSeek API 密钥和网络连接。

## 常见问题

- 无法启动：运行 `prerequisites/VC_redist.x64.exe` 后重试。
- 数据库连接失败：确认 MySQL 地址、端口、账号、密码、权限及防火墙配置。
- 图表空白：确认 `config/app.ini` 中保持 `graphicsApi=Software`。
- 需要诊断：查看程序同级的 `qmlProductManager.log`。

## 许可证

本程序依据 GNU Lesser General Public License v3.0 发布，完整条款见 `LICENSE`。
