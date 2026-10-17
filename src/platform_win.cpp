#include "platform_win.h"

#include <windows.h>

#include <cstring>

namespace suimi {

bool set_clipboard_text(const std::string& utf8) {
  if (utf8.empty()) return false;

  const int input_len = static_cast<int>(utf8.size());
  const int wide_len = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), input_len, nullptr, 0);
  if (wide_len <= 0) return false;

  std::wstring wide(static_cast<std::size_t>(wide_len), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), input_len, wide.data(), wide_len);

  if (!OpenClipboard(nullptr)) return false;

  bool ok = false;
  if (EmptyClipboard()) {
    const SIZE_T bytes = (wide.size() + 1) * sizeof(wchar_t);
    if (HGLOBAL handle = GlobalAlloc(GMEM_MOVEABLE, bytes)) {
      if (void* dst = GlobalLock(handle)) {
        std::memcpy(dst, wide.c_str(), bytes);
        GlobalUnlock(handle);
        // 成功后剪贴板接管这块内存的所有权
        if (SetClipboardData(CF_UNICODETEXT, handle) != nullptr) {
          ok = true;
        } else {
          GlobalFree(handle);
        }
      } else {
        GlobalFree(handle);
      }
    }
  }

  CloseClipboard();
  return ok;
}

}  // namespace suimi
