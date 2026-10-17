# 打包

```powershell
# PowerShell（推荐）
.\packaging\build.ps1
```

```bash
# Git Bash
bash packaging/build.sh
```

产物在 `dist/`：

- `随密-Slint-<版本>-win64-绿色版.zip`（含 `随密-Slint.exe`、`slint_cpp.dll`、`启动.bat`）
- `随密-Slint-<版本>-win64-setup.exe`（需 NSIS 或 Inno Setup）

`INSTALLER=nsis|inno|both|none` 控制要不要做安装包。

安装打包工具：

```powershell
winget install NSIS.NSIS --source winget
# 或
winget install JRSoftware.InnoSetup --source winget
```

脚本会自己跑一遍 CMake Release 构建；如果 `build/` 里已有产物，第二次跑就是秒出包。
