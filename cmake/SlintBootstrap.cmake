# 自动准备 Slint 的 C++ 预编译包。
#
# 官方 Windows 包是个 NSIS 安装器（manifest 里声明 requireAdministrator），
# 于是这里做两件事：
#   1. 用 `start /wait` 启动它 —— 走 ShellExecute 才能触发提权，直接
#      用 CMake 的 execute_process 会被内核挡下（permission denied）；
#   2. 静默参数 `/D=` 只认反斜杠路径，所以要 file(TO_NATIVE_PATH)。
# 安装目标是仓库里的 third_party/，不写系统目录，卸载直接删文件夹。
#
# 想换版本：-DSLINT_VERSION=1.18.1
# 想换位置 / 用现成的：-DSUIMI_SLINT_DIR=<目录>

function(suimi_bootstrap_slint slint_dir)
  set(installer_name "Slint-cpp-${SLINT_VERSION}-win64-MSVC-AMD64.exe")
  set(url "https://github.com/slint-ui/slint/releases/download/v${SLINT_VERSION}/${installer_name}")
  set(cache_dir "${CMAKE_BINARY_DIR}/_slint-download")
  set(installer "${cache_dir}/${installer_name}")

  if(NOT EXISTS "${installer}")
    message(STATUS "Slint 还没准备好，开始下载 ${installer_name}")
    message(STATUS "  ${url}")
    file(MAKE_DIRECTORY "${cache_dir}")
    file(DOWNLOAD "${url}" "${installer}" TLS_VERIFY ON STATUS download_status)
    list(GET download_status 0 download_code)
    list(GET download_status 1 download_message)
    if(NOT download_code EQUAL 0)
      file(REMOVE "${installer}")
      message(FATAL_ERROR
        "下载 Slint 失败：${download_message}\n"
        "  地址：${url}\n"
        "  也可以自己装好 Slint，再用 -DSUIMI_SLINT_DIR=<目录> 指过来。")
    endif()
  endif()

  if(slint_dir MATCHES " ")
    message(FATAL_ERROR
      "SUIMI_SLINT_DIR 不能带空格（NSIS 静默安装的 /D= 不支持）：${slint_dir}\n"
      "  换个没空格的路径，例如 -DSUIMI_SLINT_DIR=D:/slint-sdk")
  endif()

  file(TO_NATIVE_PATH "${slint_dir}" slint_dir_native)
  message(STATUS "静默安装 Slint ${SLINT_VERSION} → ${slint_dir}")
  message(STATUS "  （安装器要求管理员权限，可能会弹一次 UAC）")
  execute_process(
    COMMAND cmd /c start /wait "" "${installer}" /S "/D=${slint_dir_native}"
    RESULT_VARIABLE start_code)

  if(NOT EXISTS "${slint_dir}/lib/cmake/Slint/SlintConfig.cmake")
    message(FATAL_ERROR
      "Slint 没能装到 ${slint_dir}（start 返回 ${start_code}）。\n"
      "  多半是 UAC 提权被取消 / 拒绝。可以：\n"
      "    1) 用「管理员身份」重开终端再跑一次 cmake；或\n"
      "    2) 自己双击 ${installer} 装到任意目录，然后用 -DSUIMI_SLINT_DIR=<那个目录>。")
  endif()

  message(STATUS "Slint ${SLINT_VERSION} 就绪：${slint_dir}")
endfunction()
