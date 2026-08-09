# 网络资料查询报告（TASK-005：修改 Flutter 客户端构建配置：安装产物统一输出至 deploy）

> 本报告由 impm-task-coding-ws 技能生成，供编码开发阶段使用。
> 项目：云漫智企（CloudStrollOffice，cso）｜版本：v0.2.5｜任务：TASK-005
> 查询日期：2026-08-09

## 1. 查询结论摘要

| 查询项 | 结论 | 权威来源 |
| --- | --- | --- |
| Flutter Windows 产物路径 | `flutter build windows --release` 产物位于 `build\windows\x64\runner\Release\`（Flutter 3.16+ 架构化路径，官方 breaking change 确认；旧路径 `build\windows\runner\Release` 已废弃） | docs.flutter.dev 官方文档 + breaking-changes 页面 |
| Flutter Web 产物路径 | `flutter build web` 产物位于项目 `build/web` 目录（官方部署文档确认） | docs.flutter.dev deployment/web |
| Windows 可交付物构成 | exe + 同目录全部 .dll + `data/` 目录 + 目标机 Visual C++ Redistributable；exe 文件名由 `windows/CMakeLists.txt` 的 `BINARY_NAME` 决定 | docs.flutter.dev platform-integration/windows/building |
| Inno Setup 命令行打包（可选方案） | `ISCC.exe` 命令行编译 .iss 脚本；`/O` 指定输出目录、`/F` 指定输出文件名、`/Q` 安静模式；退出码 0=成功/1=参数无效/2=编译失败；当前版本 7.0.2（2026-07-13 发布） | jrsoftware.org 官方帮助 |
| 版本兼容性 | 项目 Dart SDK `^3.12.2`（对应 Flutter 3.4x 系列，远高于 3.16），x64 架构化产物路径完全适用；cs.md 已核实的 `build/windows/x64/runner/Release/` 与官方文档一致 | 官方文档与本地工程核对 |

## 2. Flutter 官方文档（构建命令与产物路径）

### 2.1 Windows 构建（docs.flutter.dev/platform-integration/windows/building）

- 构建命令：`flutter build windows --release`；
- 产物位置：`build\windows\x64\runner\Release\`，包含：
  - `cloudoffice_flutter_app.exe`（文件名由 `windows/CMakeLists.txt` 中 `set(BINARY_NAME "cloudoffice_flutter_app")` 决定）；
  - 全部 `.dll` 文件（flutter_windows.dll、dartjni.dll、插件 dll 等）；
  - `data/` 目录（flutter_assets 等应用资源）；
- **分发要求（官方原文要点）**：除 exe 外还需同目录所有 `.dll` 与 `data` 目录；目标机器需要 Visual C++ Redistributable 运行库（官方建议用 vc_redist 或随包分发 msvcp140.dll / vcruntime140.dll 等）；
- **官方 breaking change 确认**（docs.flutter.dev/release/breaking-changes/windows-build-architecture）：为支持 Windows on Arm64，Flutter 3.16 起构建路径加入目标架构目录：
  - 迁移前：`build\windows\runner\Release\hello_world.exe`
  - 迁移后（x64）：`build\windows\x64\runner\Release\hello_world.exe`
  - 迁移后（arm64）：`build\windows\arm64\runner\Release\hello_world.exe`
- 官方文档当前反映 Flutter 3.44.7（页面更新于 2026-06-08）。

### 2.2 Web 构建（docs.flutter.dev/deployment/web）

- 构建命令：`flutter build web`（release 为默认模式，可显式加 `--release`）；
- 产物位置：项目根 `build/web` 目录（官方原文：releases the application in the `/build/web` directory）；
- 产物内容：index.html、main.dart.js、assets/、icons/ 等标准 Web 部署包，整体即为最终可交付物；
- 部署方式：将 `build/web` 内容托管到任意静态 Web 服务器（Nginx 等）。

## 3. Inno Setup（Windows 安装程序打包，可选方案）

> 背景：cs.md 确认本项目当前无安装包工具配置，最终交付形式（裸 Release 目录 / 压缩包 / 安装程序 exe）由编码阶段按 F-003 决定。以下为选用"安装程序 exe"方案时的官方资料。

### 3.1 官方文档（jrsoftware.org/ishelp/topic_compilercmdline.htm）

- 命令行编译（console-mode compiler）：
  ```
  iscc [options] <script.iss>
  ```
- 关键参数：
  | 参数 | 含义 |
  | --- | --- |
  | `/O<path>` | 指定输出目录（覆盖脚本中 OutputDir） |
  | `/F<filename>` | 指定输出文件名（覆盖 OutputBaseFilename） |
  | `/Q` | 安静编译（仅打印错误） |
  | `/Qp` | 安静编译但保留进度显示 |
  | `/S<name>=<command>` | 设置签名工具 |
- 退出码：0=编译成功；1=参数无效或内部错误；2=编译失败；
- 当前版本状态（jrsoftware.org 首页，2026-07-13）：Inno Setup 7.0.2 已发布；6.x 稳定分支最新为 6.7.3（2026-05-26）。

### 3.2 Flutter 专用 ISS 脚本样例（GitHub 真实项目）

**样例 A：MixinNetwork/flutter-app 的 windows_inno_setup.iss（52 行，完整可参考）**

```iss
#define MyAppName "Mixin"
#define MyAppExeName "mixin_desktop.exe"
#define MyAppPath ".\build\windows\x64\runner\Release\" + MyAppExeName
#define MyAppVersion GetVersionNumbersString(MyAppPath)

[Setup]
AppId={{D49214E5-DD65-429B-B1F2-738F69417E4F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=.\build\
OutputBaseFilename=mixin_desktop_windows_setup_amd64
SetupIconFile=.\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes

[Files]
Source: ".\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,...}"; Flags: nowait postinstall skipifsilent
```

**样例 B：XhosaS/BluetoothManager 的 scripts/build_installer.ps1（PowerShell 编排构建+打包）**

```powershell
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
  & $Flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw "Flutter release build failed." }
  if (-not (Test-Path $Iscc)) {
    throw "Inno Setup 6 was not found at: $Iscc"
  }
  & $Iscc "installer\BluetoothAudioManager.iss"
}
finally { Pop-Location }
```

## 4. PowerShell 复制产物真实样例（GitHub）

| 仓库/文件 | 可复用片段 | 说明 |
| --- | --- | --- |
| moraxs/CyreneMusic scripts/test_windows_update.ps1 | `Copy-Item -Path "build/windows/x64/runner/Release" -Destination $oldBuildPath -Recurse -Force` | Release 目录整体复制到目标（用 -Recurse 复制最终产物目录内容） |
| GeorgeEnglezos/Scrcpy-GUI build_windows_installer.ps1 | `$ReleaseDir = 'build\windows\x64\runner\Release'`；`if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }` | 定义 Release 路径常量 + 构建失败即中止的健壮写法 |
| XhosaS/BluetoothManager scripts/package_portable.ps1 | `$release = Join-Path $projectRoot "build\windows\x64\runner\Release"`；`Copy-Item (Join-Path $release "*") (Join-Path $packageRoot "app") -Recurse -Force` | 用 Join-Path 拼路径，仅复制 Release 目录内全部内容（`*`）而非整个 build/ |

**关键要点（对照 F-004 中间产物隔离）**：所有样例均只操作 `build\windows\x64\runner\Release`（最终产物目录），从未递归复制整个 `build/`；这正符合本任务"仅复制最终产物文件、严禁整目录递归复制构建输出目录"的验收标准（AC-4）。

## 5. 版本兼容性核对（步骤 5）

| 项目 | 版本 | 兼容性结论 |
| --- | --- | --- |
| 项目 Dart SDK | `^3.12.2`（pubspec.yaml，对应 Flutter 3.4x 系列） | ✅ 远高于 Flutter 3.16（x64 架构化路径生效版本），`build/windows/x64/runner/Release/` 路径 100% 适用；与 cs.md 已核实的本机构建产物路径一致 |
| Flutter 官方文档 | 反映 Flutter 3.44.7（2026-06-08 更新） | ✅ 查询的 Windows/Web 产物路径与构建命令为当前官方结论，无版本迁移风险 |
| Inno Setup（若采用安装包方案） | 官方最新 7.0.2 / 6.x 稳定 6.7.3 | ✅ 与本项目无直接版本依赖；选用时建议固定版本（如 6.x 稳定版）并记录到构建脚本注释，脚本内仅依赖 ISCC.exe 标准参数（/O、/F、/Q、退出码），跨小版本稳定 |
| Visual C++ Redistributable | 目标机器运行库 | ⚠️ 官方明确要求；本任务若采用"裸 Release 目录复制"交付，须在交付说明中标注（可参考 cs.md 已记录内容），不属本任务代码范围 |

## 6. 编码落地建议（基于官方文档与真实样例汇总）

1. **新建客户端构建脚本**（cloudoffice-flutter-app 下新建，如 `build-release.ps1`/`build-release.sh`），流程参照 XhosaS 样例：
   - `flutter pub get`（可选）→ `flutter build windows --release`；
   - `$LASTEXITCODE -ne 0` 检查构建失败即中止；
2. **Windows 产物复制**（参照 CyreneMusic/package_portable 样例）：
   - 定义 `$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"`；
   - `Copy-Item (Join-Path $ReleaseDir "*") $DeployDir -Recurse -Force`（或按 cs.md 建议仅复制 exe + 3 个 dll + data/）；
   - **严禁** `Copy-Item build` 整目录递归（AC-4）；
3. **Web 产物复制**（若任务覆盖 Web）：`Copy-Item "build\web\*" $DeployWebDir -Recurse -Force`，Web 包整体即最终可交付物；
4. **产物落点**：与后端 jar 一致放 deploy 根目录，或建 `deploy/cloudoffice-flutter-app/` 子目录防同名冲突（与 deploy/scripts 脚本引用约定保持一致的方案优先，由编码阶段权衡）；
5. **脚本路径定位**：沿用项目既有约定（cs.md 第 5 节：`$PSScriptRoot` 上溯定位项目根/deploy），避免硬编码绝对路径；
6. **若采用安装程序 exe 方案**：参考 MixinNetwork ISS 脚本 + `ISCC.exe /Q /O"deploy" /F"cloudoffice-flutter-app-setup" setup.iss` 编译，OutputDir 直接指向 deploy（产物最终落点）即可，中间 .iss 脚本与 Release 目录留在 build/ 不进入 deploy。

## 7. 参考资料链接

| 资料 | 链接 |
| --- | --- |
| Flutter 官方：构建 Windows 应用 | https://docs.flutter.dev/platform-integration/windows/building |
| Flutter 官方 breaking change：Windows 构建路径加入架构目录 | https://docs.flutter.dev/release/breaking-changes/windows-build-architecture |
| Flutter 官方：构建 Web 应用（部署） | https://docs.flutter.dev/deployment/web |
| Inno Setup 官方帮助：命令行编译器 | https://jrsoftware.org/ishelp/topic_compilercmdline.htm |
| Inno Setup 官方首页（版本发布记录） | https://jrsoftware.org/ |
| 真实样例：MixinNetwork flutter-app windows_inno_setup.iss | https://github.com/MixinNetwork/flutter-app/blob/main/windows_inno_setup.iss |
| 真实样例：XhosaS/BluetoothManager scripts/build_installer.ps1 | https://github.com/XhosaS/BluetoothManager/blob/main/scripts/build_installer.ps1 |
| 真实样例：moraxs/CyreneMusic scripts/test_windows_update.ps1 | https://github.com/moraxs/CyreneMusic/blob/main/scripts/test_windows_update.ps1 |
| 真实样例：GeorgeEnglezos/Scrcpy-GUI build_windows_installer.ps1 | https://github.com/GeorgeEnglezos/Scrcpy-GUI/blob/main/ScrcpyGui/build_windows_installer.ps1 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
