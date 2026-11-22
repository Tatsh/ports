// std::hash<std::filesystem::path> (LWG 3657) is only provided by libc++ 17 and newer.
#pragma once
#if defined(__cplusplus) && __cplusplus >= 201703L
#include <filesystem>
#include <functional>
#if defined(_LIBCPP_VERSION) && _LIBCPP_VERSION < 170000
template <> struct std::hash<std::filesystem::path> {
    std::size_t operator()(const std::filesystem::path &p) const noexcept {
        return std::filesystem::hash_value(p);
    }
};
#endif
#endif
