#pragma once

#include <string>
#include <vector>

/// 生成模式：与 Rust / ImGui / Qt 版保持一致
enum class Mode { Password, Username, Nickname };

struct PasswordOptions {
  int length = 20;
  bool lowercase = true;
  bool uppercase = true;
  bool digits = true;
  bool symbols = true;
  bool exclude_ambiguous = true;
};

struct Strength {
  std::string label = "—";
  double bits = 0.0;
  /// 0.0 ~ 1.0，用于进度条
  float ratio = 0.0f;
};

/// 勾选字符集拼出的字符池（已按需剔除易混字符）
std::string password_charset(const PasswordOptions& opts);

/// 由长度与字符池大小估算熵值（bit）
Strength password_strength(const PasswordOptions& opts);

std::string generate_password(const PasswordOptions& opts);
std::vector<std::string> generate_passwords(const PasswordOptions& opts, int count);

/// 小写字母开头，可含数字与下划线
std::string generate_username(int length);

/// 内置中文词库随机组合
std::string generate_nickname();
