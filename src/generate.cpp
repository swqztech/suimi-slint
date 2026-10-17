#include "generate.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <random>
#include <string>

namespace {

constexpr const char* kLower = "abcdefghijklmnopqrstuvwxyz";
constexpr const char* kUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
constexpr const char* kDigits = "0123456789";
constexpr const char* kSymbols = "!@#$%^&*()-_=+[]{}|;:,.<>?";
/// 易混字符：0 O o I l 1
constexpr const char* kAmbiguous = "0OoIl1";

/// 兜底随机源：仅在系统随机源不可用时启用，仍用系统熵播种。
std::mt19937_64& fallback_rng() {
  static std::mt19937_64 gen = [] {
    std::seed_seq seq{static_cast<unsigned>(std::chrono::high_resolution_clock::now()
                                                .time_since_epoch()
                                                .count()),
                      static_cast<unsigned>(std::random_device{}()),
                      static_cast<unsigned>(std::random_device{}())};
    return std::mt19937_64(seq);
  }();
  return gen;
}

/// 首选系统随机源：Windows 上 std::random_device 由系统密码学 RNG 提供。
bool system_random_usable() {
  static const bool usable = [] {
    try {
      (void)std::random_device{}();
      return true;
    } catch (...) {
      return false;
    }
  }();
  return usable;
}

/// [0, bound) 上的均匀整数，bound 必须大于 0
std::uint32_t random_below(std::uint32_t bound) {
  std::uniform_int_distribution<std::uint32_t> dist(0, bound - 1);
  if (system_random_usable()) {
    static std::random_device rd;
    try {
      return dist(rd);
    } catch (...) {
      // 落到兜底分支
    }
  }
  return dist(fallback_rng());
}

std::string filter_ambiguous(const char* s, bool exclude) {
  if (!exclude) return s;
  std::string out;
  for (const char* p = s; *p != '\0'; ++p) {
    if (std::strchr(kAmbiguous, *p) == nullptr) out.push_back(*p);
  }
  return out;
}

}  // namespace

std::string password_charset(const PasswordOptions& opts) {
  std::string pool;
  if (opts.lowercase) pool += filter_ambiguous(kLower, opts.exclude_ambiguous);
  if (opts.uppercase) pool += filter_ambiguous(kUpper, opts.exclude_ambiguous);
  if (opts.digits) pool += filter_ambiguous(kDigits, opts.exclude_ambiguous);
  if (opts.symbols) pool += kSymbols;
  return pool;
}

Strength password_strength(const PasswordOptions& opts) {
  const std::string charset = password_charset(opts);
  Strength s;
  if (charset.empty() || opts.length <= 0) return s;

  const double bits = static_cast<double>(opts.length) * std::log2(static_cast<double>(charset.size()));
  s.bits = bits;
  s.ratio = static_cast<float>(std::min(bits / 128.0, 1.0));
  if (bits < 40.0) s.label = "很弱";
  else if (bits < 60.0) s.label = "弱";
  else if (bits < 80.0) s.label = "中等";
  else if (bits < 100.0) s.label = "强";
  else s.label = "很强";
  return s;
}

std::string generate_password(const PasswordOptions& opts) {
  const std::string charset = password_charset(opts);
  if (charset.empty() || opts.length <= 0) return {};

  std::string out;
  out.reserve(static_cast<std::size_t>(opts.length));
  for (int i = 0; i < opts.length; ++i) {
    out.push_back(charset[random_below(static_cast<std::uint32_t>(charset.size()))]);
  }
  return out;
}

std::vector<std::string> generate_passwords(const PasswordOptions& opts, int count) {
  std::vector<std::string> out;
  if (count <= 0) return out;
  out.reserve(static_cast<std::size_t>(count));
  for (int i = 0; i < count; ++i) out.push_back(generate_password(opts));
  return out;
}

std::string generate_username(int length) {
  length = std::clamp(length, 4, 32);
  const std::string letters = kLower;
  const std::string body = "abcdefghijklmnopqrstuvwxyz0123456789_";

  std::string s;
  s.reserve(static_cast<std::size_t>(length));
  s.push_back(letters[random_below(static_cast<std::uint32_t>(letters.size()))]);
  while (static_cast<int>(s.size()) < length) {
    s.push_back(body[random_below(static_cast<std::uint32_t>(body.size()))]);
  }
  return s;
}

namespace {

constexpr std::uint32_t kNounCount = 16;
constexpr std::uint32_t kAdjCount = 16;

const char* const kNickAdj[kAdjCount] = {"静默", "浅夏", "远山", "微光", "逐风", "清欢", "星落", "云深",
                                         "听雨", "拾穗", "半盏", "南巷", "北鸢", "青衫", "白茶", "晚钟"};

const char* const kNickNoun[kNounCount] = {"旅人", "行者", "墨客", "观星者", "拾梦人", "渡舟", "栖鹤", "听潮",
                                           "煮茶", "折枝", "问月", "寻鹿", "枕书", "候风", "写序", "归人"};

}  // namespace

std::string generate_nickname() {
  const char* adj = kNickAdj[random_below(kAdjCount)];
  const char* noun = kNickNoun[random_below(kNounCount)];
  // 约 35% 带两位数字后缀（与 Rust 版一致）
  if (random_below(100) < 35) {
    return std::string(adj) + noun + std::to_string(10 + random_below(90));
  }
  return std::string(adj) + noun;
}
