#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep -E 'project\(.*VERSION' "$ROOT/CMakeLists.txt" | sed -E 's/.*VERSION\s+([0-9.]+).*/\1/')"
INSTALLER_MODE="${INSTALLER:-both}"

CMAKE="$(command -v cmake || true)"
if [[ -z "$CMAKE" ]]; then
  for p in \
    "/c/Program Files/CMake/bin/cmake.exe" \
    "$LOCALAPPDATA/Microsoft/WinGet/Packages/Kitware.CMake_Microsoft.Winget.Source_8wekyb3d8bbwe/cmake-"*/bin/cmake.exe
  do
    [[ -x "$p" ]] && CMAKE="$p" && break
  done
fi
[[ -n "$CMAKE" && -x "$CMAKE" ]] || { echo "需要 cmake"; exit 1; }

(cd "$ROOT" && "$CMAKE" -B build -DCMAKE_BUILD_TYPE=Release && "$CMAKE" --build build --config Release)

EXE_SRC="$ROOT/build/Release/suimi-slint.exe"
[[ -f "$EXE_SRC" ]] || EXE_SRC="$ROOT/build/suimi-slint.exe"
[[ -f "$EXE_SRC" ]] || { echo "未找到 suimi-slint.exe"; exit 1; }

DIST="$ROOT/dist"
PORTABLE_NAME="随密-Slint-${VERSION}-win64-绿色版"
PORTABLE_DIR="$DIST/$PORTABLE_NAME"
rm -rf "$DIST"
mkdir -p "$PORTABLE_DIR"
cp -f "$EXE_SRC" "$PORTABLE_DIR/随密-Slint.exe"
for dll in \
  "$ROOT/build/Release/slint_cpp.dll" \
  "$ROOT/build/_deps/slint-build/slint_cpp.dll"; do
  [[ -f "$dll" ]] && cp -f "$dll" "$PORTABLE_DIR/" && break
done
[[ -f "$PORTABLE_DIR/slint_cpp.dll" ]] || { echo "缺少 slint_cpp.dll，请先完整编译"; exit 1; }
cp -f "$ROOT/packaging/stage/"* "$PORTABLE_DIR/"
(cd "$DIST" && tar -a -cf "${PORTABLE_NAME}.zip" "$(basename "$PORTABLE_DIR")")

INSTALLER_STAGE="$ROOT/packaging/installer-stage"
rm -rf "$INSTALLER_STAGE" && mkdir -p "$INSTALLER_STAGE"
cp -r "$PORTABLE_DIR"/* "$INSTALLER_STAGE/"

SETUP_EXE="$DIST/随密-Slint-${VERSION}-win64-setup.exe"
SETUP_ASCII="$DIST/Suimi-Slint-${VERSION}-win64-setup.exe"
for p in "/c/Program Files (x86)/NSIS/makensis.exe" "/c/Program Files/NSIS/makensis.exe"; do
  if [[ -f "$p" && ( "$INSTALLER_MODE" == "nsis" || "$INSTALLER_MODE" == "both" ) ]]; then
    "$p" "//INPUTCHARSET" "UTF8" "//DVERSION=$VERSION" \
      "//DSTAGE_DIR=$(cygpath -w "$INSTALLER_STAGE")" \
      "//DOUTFILE=$(cygpath -w "$SETUP_ASCII")" \
      "$(cygpath -w "$ROOT/packaging/nsis/setup.nsi")"
    mv -f "$SETUP_ASCII" "$SETUP_EXE"
    break
  fi
done
echo "Done: $DIST"
