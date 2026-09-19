[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
    [string]$Version = '1.0',

    [Parameter()]
    [string]$QtRoot = 'E:\Qt\6.8.3\mingw_64',

    [Parameter()]
    [string]$MinGwRoot = 'E:\Qt\Tools\mingw1310_64',

    [Parameter()]
    [string]$MySqlRoot = 'C:\Program Files\MySQL\MySQL Server 9.3',

    [Parameter()]
    [string]$VcRedistPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-FileExists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description 不存在：$Path"
    }
}

function Assert-DirectoryExists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Description 不存在：$Path"
    }
}

function Remove-WorkspaceChildDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceRoot,

        [Parameter(Mandatory)]
        [string]$TargetPath
    )

    # 删除旧构建目录前先比较规范化绝对路径，避免参数错误导致递归删除到仓库外部。
    $workspacePrefix = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not $targetFullPath.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "拒绝删除工作区外目录：$targetFullPath"
    }

    if (Test-Path -LiteralPath $targetFullPath) {
        Remove-Item -LiteralPath $targetFullPath -Recurse -Force
    }
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Executable,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "命令执行失败（退出码 $LASTEXITCODE）：$Executable $($Arguments -join ' ')"
    }
}

$scriptDirectory = Split-Path -Parent $PSCommandPath
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDirectory '..'))
$projectFile = Join-Path $repositoryRoot 'qmlProductManager.pro'
$qmlDirectory = Join-Path $repositoryRoot 'qml'
$buildDirectory = Join-Path $repositoryRoot 'build\release-package-build'
$packageRoot = Join-Path $repositoryRoot 'build\release-package'
$stageDirectory = Join-Path $packageRoot "ProductManager-v$Version-win64"

$qmake = Join-Path $QtRoot 'bin\qmake.exe'
$windeployqt = Join-Path $QtRoot 'bin\windeployqt.exe'
$mingwMake = Join-Path $MinGwRoot 'bin\mingw32-make.exe'
$mysqlDriver = Join-Path $QtRoot 'plugins\sqldrivers\qsqlmysql.dll'
$mysqlClient = Join-Path $MySqlRoot 'lib\libmysql.dll'
$mysqlSsl = Join-Path $MySqlRoot 'bin\libssl-3-x64.dll'
$mysqlCrypto = Join-Path $MySqlRoot 'bin\libcrypto-3-x64.dll'

Assert-FileExists -Path $projectFile -Description 'qmake 项目文件'
Assert-DirectoryExists -Path $qmlDirectory -Description 'QML 源码目录'
Assert-FileExists -Path $qmake -Description 'qmake'
Assert-FileExists -Path $windeployqt -Description 'windeployqt'
Assert-FileExists -Path $mingwMake -Description 'mingw32-make'
Assert-FileExists -Path $mysqlDriver -Description 'Qt QMYSQL 驱动'
Assert-FileExists -Path $mysqlClient -Description 'MySQL 客户端库'
Assert-FileExists -Path $mysqlSsl -Description 'MySQL OpenSSL SSL 库'
Assert-FileExists -Path $mysqlCrypto -Description 'MySQL OpenSSL Crypto 库'

if ([string]::IsNullOrWhiteSpace($VcRedistPath)) {
    $packageCache = 'C:\ProgramData\Package Cache'
    if (Test-Path -LiteralPath $packageCache) {
        $VcRedistPath = Get-ChildItem -LiteralPath $packageCache -Filter 'VC_redist.x64.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
}
Assert-FileExists -Path $VcRedistPath -Description 'Microsoft Visual C++ x64 Redistributable'

Remove-WorkspaceChildDirectory -WorkspaceRoot $repositoryRoot -TargetPath $buildDirectory
Remove-WorkspaceChildDirectory -WorkspaceRoot $repositoryRoot -TargetPath $packageRoot
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $stageDirectory -Force | Out-Null

$oldPath = $env:PATH
$env:PATH = "$(Join-Path $MinGwRoot 'bin');$oldPath"
try {
    Push-Location $buildDirectory
    try {
        Invoke-CheckedCommand -Executable $qmake -Arguments @(
            '-o', 'Makefile', $projectFile, '-spec', 'win32-g++', 'CONFIG+=release'
        )
        Invoke-CheckedCommand -Executable $mingwMake -Arguments @('-f', 'Makefile', '-j1')
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:PATH = $oldPath
}

$builtExecutable = Join-Path $buildDirectory 'release\qmlProductManager.exe'
$stagedExecutable = Join-Path $stageDirectory 'qmlProductManager.exe'
Assert-FileExists -Path $builtExecutable -Description 'Release 可执行程序'
Copy-Item -LiteralPath $builtExecutable -Destination $stagedExecutable -Force

Invoke-CheckedCommand -Executable $windeployqt -Arguments @(
    '--release',
    '--compiler-runtime',
    '--no-translations',
    '--qmldir', $qmlDirectory,
    $stagedExecutable
)

# windeployqt 不会完整收集 QMYSQL 的第三方依赖，因此这里显式复制并在下方逐项校验。
$sqlDriverDirectory = Join-Path $stageDirectory 'sqldrivers'
$configDirectory = Join-Path $stageDirectory 'config'
$databaseDirectory = Join-Path $stageDirectory 'database'
$prerequisiteDirectory = Join-Path $stageDirectory 'prerequisites'
New-Item -ItemType Directory -Path $sqlDriverDirectory, $configDirectory, $databaseDirectory, $prerequisiteDirectory -Force | Out-Null

Copy-Item -LiteralPath $mysqlDriver -Destination (Join-Path $sqlDriverDirectory 'qsqlmysql.dll') -Force
Copy-Item -LiteralPath $mysqlClient -Destination (Join-Path $stageDirectory 'libmysql.dll') -Force
Copy-Item -LiteralPath $mysqlSsl -Destination (Join-Path $stageDirectory 'libssl-3-x64.dll') -Force
Copy-Item -LiteralPath $mysqlCrypto -Destination (Join-Path $stageDirectory 'libcrypto-3-x64.dll') -Force
Copy-Item -LiteralPath $VcRedistPath -Destination (Join-Path $prerequisiteDirectory 'VC_redist.x64.exe') -Force

# 发布配置只能由公开模板生成，绝不读取或复制开发者本机的 config/app.ini。
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'config\app.ini.example') -Destination (Join-Path $configDirectory 'app.ini') -Force
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'config\app.ini.example') -Destination (Join-Path $configDirectory 'app.ini.example') -Force
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'database\schema.sql') -Destination (Join-Path $databaseDirectory 'schema.sql') -Force
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'README.release.md') -Destination (Join-Path $stageDirectory 'README.md') -Force
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'LICENSE') -Destination (Join-Path $stageDirectory 'LICENSE') -Force
Copy-Item -LiteralPath (Join-Path $scriptDirectory 'release.gitignore') -Destination (Join-Path $stageDirectory '.gitignore') -Force

$sourceCommit = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sourceCommit)) {
    throw '无法读取当前源码提交。请确认脚本在 Git 仓库中运行。'
}

@(
    "Version: V$Version"
    "Source commit: $sourceCommit"
    "Built at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath (Join-Path $stageDirectory 'SOURCE_COMMIT.txt') -Encoding utf8

$forbiddenFiles = @(
    'database_server_config.enc',
    'login_credentials.enc',
    'login.ini',
    'qmlProductManager.log'
)
foreach ($forbiddenFile in $forbiddenFiles) {
    $match = Get-ChildItem -LiteralPath $stageDirectory -Recurse -File -Filter $forbiddenFile -ErrorAction SilentlyContinue
    if ($match) {
        throw "发布目录包含禁止文件：$($match.FullName -join ', ')"
    }
}

$requiredRelativePaths = @(
    'qmlProductManager.exe',
    'Qt6Core.dll',
    'Qt6Gui.dll',
    'Qt6Qml.dll',
    'Qt6Quick.dll',
    'Qt6Sql.dll',
    'sqldrivers\qsqlmysql.dll',
    'libmysql.dll',
    'libssl-3-x64.dll',
    'libcrypto-3-x64.dll',
    'config\app.ini',
    'database\schema.sql',
    'prerequisites\VC_redist.x64.exe',
    'README.md',
    'LICENSE',
    'SOURCE_COMMIT.txt'
)
foreach ($relativePath in $requiredRelativePaths) {
    Assert-FileExists -Path (Join-Path $stageDirectory $relativePath) -Description "发布文件 $relativePath"
}

$checksumPath = Join-Path $stageDirectory 'SHA256SUMS.txt'
$checksumLines = Get-ChildItem -LiteralPath $stageDirectory -Recurse -File |
    Where-Object { $_.FullName -ne $checksumPath } |
    Sort-Object FullName |
    ForEach-Object {
        $relativePath = [System.IO.Path]::GetRelativePath($stageDirectory, $_.FullName).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
$checksumLines | Set-Content -LiteralPath $checksumPath -Encoding utf8

$packageFiles = Get-ChildItem -LiteralPath $stageDirectory -Recurse -File
$packageSize = ($packageFiles | Measure-Object -Property Length -Sum).Sum
Write-Host "Release 打包完成：$stageDirectory"
Write-Host "文件数量：$($packageFiles.Count)"
Write-Host ('总大小：{0:N2} MiB' -f ($packageSize / 1MB))
