$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Packaging = Join-Path $Root "packaging"
$Stage = Join-Path $Packaging "stage"
$Dist = Join-Path $Root "dist"
$InstallerMode = if ($env:INSTALLER) { $env:INSTALLER.ToLower() } else { "both" }

$cm = Get-Content (Join-Path $Root "CMakeLists.txt") -Raw
if ($cm -notmatch 'project\(\s*suimi-slint\s+VERSION\s+([0-9.]+)') { throw "CMakeLists.txt VERSION not found" }
$Version = $Matches[1]

function Find-Cmake {
    $cmd = Get-Command cmake -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    @(
        "${env:ProgramFiles}\CMake\bin\cmake.exe",
        "${env:ProgramFiles(x86)}\CMake\bin\cmake.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Kitware.CMake_Microsoft.Winget.Source_8wekyb3d8bbwe\cmake-4.4.4-windows-x86_64\bin\cmake.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$cmake = Find-Cmake
if (-not $cmake) { throw "未找到 cmake，请安装: winget install Kitware.CMake" }

Write-Host "==> CMake build (Release)"
Push-Location $Root
& $cmake -B build -DCMAKE_BUILD_TYPE=Release
& $cmake --build build --config Release
Pop-Location

$exeCandidates = @(
    (Join-Path $Root "build\Release\suimi.exe"),
    (Join-Path $Root "build\suimi.exe")
)
$exeSrc = $exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exeSrc) { throw "未找到 suimi.exe，请安装 Visual Studio C++ 工具链后重试" }

$dllSrc = Join-Path (Split-Path $exeSrc -Parent) "slint_cpp.dll"
if (-not (Test-Path $dllSrc)) { throw "未找到 slint_cpp.dll（Slint 运行时），请先确认构建成功" }

$portableName = "随密-Slint-$Version-win64-绿色版"
$portableDir = Join-Path $Dist $portableName
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Path $portableDir -Force | Out-Null
Copy-Item $exeSrc (Join-Path $portableDir "随密-Slint.exe") -Force
Copy-Item $dllSrc $portableDir -Force
Copy-Item (Join-Path $Stage "启动.bat") $portableDir -Force
Copy-Item (Join-Path $Stage "使用说明.txt") $portableDir -Force

$zipPath = Join-Path $Dist "$portableName.zip"
Push-Location $Dist
tar -a -cf $zipPath (Split-Path $portableDir -Leaf)
Pop-Location
Write-Host "ZIP: $zipPath"

$installerStage = Join-Path $Packaging "installer-stage"
if (Test-Path $installerStage) { Remove-Item $installerStage -Recurse -Force }
New-Item -ItemType Directory -Path $installerStage -Force | Out-Null
Copy-Item (Join-Path $portableDir "*") $installerStage -Recurse -Force

$setupExe = Join-Path $Dist "随密-Slint-$Version-win64-setup.exe"
$built = $false

$makensis = @(
    "${env:ProgramFiles(x86)}\NSIS\makensis.exe",
    "${env:ProgramFiles}\NSIS\makensis.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($makensis -and $InstallerMode -in @("nsis", "both")) {
    $setupAscii = Join-Path $Dist "Suimi-Slint-$Version-win64-setup.exe"
    $nsi = Join-Path $Packaging "nsis\setup.nsi"
    & $makensis "/INPUTCHARSET" "UTF8" "/DVERSION=$Version" "/DSTAGE_DIR=$installerStage" "/DOUTFILE=$setupAscii" $nsi
    Move-Item -Force $setupAscii $setupExe
    Write-Host "NSIS: $setupExe"
    $built = $true
}

if (-not $built -and $InstallerMode -in @("inno", "both")) {
    $iscc = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($iscc) {
        $iss = Join-Path $Packaging "inno\setup.iss"
        & $iscc $iss "/DMyAppVersion=$Version" "/DStageDir=$installerStage" "/DOutputDir=$Dist"
        $built = $true
    }
}

if (-not $built -and $InstallerMode -ne "none") {
    Write-Host "Install NSIS or Inno to build setup.exe" -ForegroundColor Yellow
}
Write-Host "Done: $Dist"
