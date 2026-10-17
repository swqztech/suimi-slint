// 随密 (suimi) — C++ + Slint
//
// 界面在 ui/suimi.slint，随机生成在 src/generate.cpp，这里只做「接线」。

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX

#include "suimi.h"  // 由 ui/suimi.slint 生成（slint_target_sources）

#include "generate.h"
#include "platform_win.h"

#include <slint.h>
#include <windows.h>

#include <algorithm>
#include <memory>
#include <string>
#include <vector>

namespace {

std::string to_utf8(const slint::SharedString& s) { return std::string(std::string_view(s)); }

PasswordOptions read_password_options(const AppWindow& ui) {
  PasswordOptions opts;
  opts.length = std::clamp(static_cast<int>(ui.get_pw_length()), 6, 64);
  opts.lowercase = ui.get_use_lowercase();
  opts.uppercase = ui.get_use_uppercase();
  opts.digits = ui.get_use_digits();
  opts.symbols = ui.get_use_symbols();
  opts.exclude_ambiguous = ui.get_exclude_ambiguous();
  return opts;
}

/// 把结果灌进界面：lines 用于逐行展示，copy-text 用于整段复制
void show_lines(AppWindow& ui, const std::vector<std::string>& lines) {
  auto model = std::make_shared<slint::VectorModel<slint::SharedString>>();
  std::string joined;
  for (std::size_t i = 0; i < lines.size(); ++i) {
    model->push_back(slint::SharedString(std::string_view(lines[i])));
    if (i != 0) joined.push_back('\n');
    joined += lines[i];
  }
  ui.set_lines(std::move(model));
  ui.set_copy_text(slint::SharedString(std::string_view(joined)));
}

void refresh_strength(AppWindow& ui) {
  const Strength strength = password_strength(read_password_options(ui));
  ui.set_strength_label(slint::SharedString(std::string_view(strength.label)));
  ui.set_strength_bits(static_cast<float>(strength.bits));
  ui.set_strength_ratio(strength.ratio);
}

void roll_once(AppWindow& ui) {
  switch (static_cast<Mode>(ui.get_mode())) {
    case Mode::Username:
      show_lines(ui, {generate_username(static_cast<int>(ui.get_user_length()))});
      break;
    case Mode::Nickname:
      show_lines(ui, {generate_nickname()});
      break;
    case Mode::Password:
    default:
      show_lines(ui, {generate_password(read_password_options(ui))});
      refresh_strength(ui);
      break;
  }
}

void roll_six(AppWindow& ui) {
  const Mode mode = static_cast<Mode>(ui.get_mode());
  if (mode == Mode::Password) {
    show_lines(ui, generate_passwords(read_password_options(ui), 6));
    refresh_strength(ui);
    return;
  }

  std::vector<std::string> lines;
  lines.reserve(6);
  for (int i = 0; i < 6; ++i) {
    lines.push_back(mode == Mode::Username
                        ? generate_username(static_cast<int>(ui.get_user_length()))
                        : generate_nickname());
  }
  show_lines(ui, lines);
}

void copy_to_clipboard(AppWindow& ui, const std::string& text) {
  if (text.empty()) return;
  ui.set_toast(suimi::set_clipboard_text(text) ? "已复制" : "复制失败");
}

void copy_all(AppWindow& ui) { copy_to_clipboard(ui, to_utf8(ui.get_copy_text())); }

void copy_line(AppWindow& ui, int index) {
  const auto model = ui.get_lines();
  if (!model || index < 0) return;
  const auto row = model->row_data(static_cast<std::size_t>(index));
  if (!row.has_value()) return;
  copy_to_clipboard(ui, to_utf8(*row));
}

/// 回调里只拿弱引用，避免 ComponentHandle 与组件互相持有造成循环
template <typename Functor>
void bind(const std::shared_ptr<slint::ComponentWeakHandle<AppWindow>>& weak, Functor&& callback) {
  if (auto handle = weak->lock()) callback(**handle);
}

int run_app() {
  auto ui = AppWindow::create();

  // 打开就有结果，和 Rust 版 new() 里先掷一次的行为一致
  roll_once(*ui);
  refresh_strength(*ui);

  auto weak = std::make_shared<slint::ComponentWeakHandle<AppWindow>>(ui);

  ui->on_request_roll([weak] { bind(weak, [](AppWindow& w) { roll_once(w); }); });
  ui->on_request_roll_six([weak] { bind(weak, [](AppWindow& w) { roll_six(w); }); });
  ui->on_request_copy_all([weak] { bind(weak, [](AppWindow& w) { copy_all(w); }); });
  ui->on_request_copy_line(
      [weak](int index) { bind(weak, [index](AppWindow& w) { copy_line(w, index); }); });

  // 切模式：换模式后立刻掷一次
  ui->on_mode_changed([weak](int mode) {
    bind(weak, [mode](AppWindow& w) {
      w.set_mode(mode);
      roll_once(w);
    });
  });

  // 勾选项 / 长度变化：只重算强度，结果保持不动（与其它版本一致）
  ui->on_options_changed([weak] { bind(weak, [](AppWindow& w) { refresh_strength(w); }); });

  ui->run();
  return 0;
}

}  // namespace

// GUI 子系统入口：不弹控制台窗口
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) { return run_app(); }
