# suimi-slint

[随密](https://github.com/swqztech/suimi) 的 **C++ + [Slint](https://slint.dev/)** 实现，功能与 ImGui 版一致。

## 环境

- Windows 10/11 x64
- CMake 3.21+
- Visual Studio 2022（MSVC）
- **Rust**（Slint 编译 `.slint` 时需要，`rustup` 安装即可）

## 构建

```powershell
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
# build\Release\suimi-slint.exe
```

首次构建会通过 FetchContent 拉取 Slint，耗时较长。默认 **动态链接** Slint：发布需 `suimi-slint.exe` + 同目录 `slint_cpp.dll`（构建后会自动复制到 `build/Release`）。

若曾切换静/动态链接，请删掉 `build` 再完整重编。

## 打包

```bash
bash packaging/build.sh
```

## 功能

密码 / 用户名 / 网名、强度估计、复制、一次六个；逻辑在 `src/generate.cpp`，界面在 `ui/suimi.slint`。

构建 Slint 时需 **Rust 1.85.x**（见仓库根目录 `rust-toolchain.toml`），避免与 Slint 1.9 在 rustc 1.97+ 上不兼容。
