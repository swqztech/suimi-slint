#pragma once

#include <string>

namespace suimi {

/// 把 UTF-8 文本写入 Windows 剪贴板（CF_UNICODETEXT）。成功返回 true。
bool set_clipboard_text(const std::string& utf8);

}  // namespace suimi
