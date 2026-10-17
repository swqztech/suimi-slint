cmake_minimum_required(VERSION 3.21)
project(suimi-slint VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
  add_compile_options(/utf-8)
endif()

include(FetchContent)
# 动态链接 Slint：exe 较小，需同目录 slint_cpp.dll
set(BUILD_SHARED_LIBS ON CACHE BOOL "Link Slint as shared library (slint_cpp.dll)" FORCE)
FetchContent_Declare(
  slint
  GIT_REPOSITORY https://github.com/slint-ui/slint.git
  GIT_TAG v1.9.2
  GIT_SHALLOW TRUE
  SOURCE_SUBDIR api/cpp
)
FetchContent_MakeAvailable(slint)

add_executable(suimi-slint WIN32
  src/main.cpp
  src/generate.cpp
  src/platform_win.cpp
)
target_include_directories(suimi-slint PRIVATE src)

slint_target_sources(suimi-slint ui/suimi.slint)
target_link_libraries(suimi-slint PRIVATE Slint::Slint user32)

if(MSVC)
  target_compile_definitions(suimi-slint PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

set(SLINT_RUNTIME_DLL "${CMAKE_BINARY_DIR}/_deps/slint-build/slint_cpp.dll")
add_custom_command(
  TARGET suimi-slint POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SLINT_RUNTIME_DLL}" "$<TARGET_FILE_DIR:suimi-slint>"
  COMMENT "Copy slint_cpp.dll next to executable")
