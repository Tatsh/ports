// C++20 library pieces that UnleashedRecomp uses and that older libc++ lacks, taken from the
// libc++ polyfill in the eglantine port. Included ahead of UnleashedRecomp's precompiled header.
//
// - std::hash<std::filesystem::path> (libc++ 17).
// - std::atomic_ref (libc++ 19), on the compiler's __atomic builtins.

#pragma once

#include <version>

#if defined(__cplusplus) && __cplusplus >= 202002L && defined(_LIBCPP_VERSION) && \
    _LIBCPP_VERSION < 170000

#include <cstddef>
#include <filesystem>
#include <functional>

namespace std {

template <>
struct hash<filesystem::path> {
    size_t operator()(const filesystem::path& p) const noexcept {
        return filesystem::hash_value(p);
    }
};

} // namespace std

#endif

#if defined(__cplusplus) && __cplusplus >= 202002L && !defined(__cpp_lib_atomic_ref)

#include <atomic>
#include <cstddef>
#include <memory>
#include <type_traits>

namespace std {

template <class T>
class atomic_ref {
    static_assert(is_trivially_copyable_v<T>, "atomic_ref needs a trivially copyable type");

    static constexpr int order(memory_order m) {
        switch (m) {
        case memory_order_relaxed:
            return __ATOMIC_RELAXED;
        case memory_order_consume:
            return __ATOMIC_CONSUME;
        case memory_order_acquire:
            return __ATOMIC_ACQUIRE;
        case memory_order_release:
            return __ATOMIC_RELEASE;
        case memory_order_acq_rel:
            return __ATOMIC_ACQ_REL;
        default:
            return __ATOMIC_SEQ_CST;
        }
    }
    // The failure order of a compare-exchange may not be a release order.
    static constexpr memory_order failure(memory_order m) {
        return m == memory_order_acq_rel   ? memory_order_acquire
               : m == memory_order_release ? memory_order_relaxed
                                           : m;
    }

    T* ptr;

public:
    using value_type = T;
    static constexpr size_t required_alignment = alignof(T) < sizeof(T) && sizeof(T) <= 16 &&
                                                         (sizeof(T) & (sizeof(T) - 1)) == 0
                                                     ? sizeof(T)
                                                     : alignof(T);
    static constexpr bool is_always_lock_free = __atomic_always_lock_free(sizeof(T), 0);

    explicit atomic_ref(T& obj) noexcept : ptr(addressof(obj)) {}
    atomic_ref(const atomic_ref&) noexcept = default;
    atomic_ref& operator=(const atomic_ref&) = delete;

    bool is_lock_free() const noexcept { return __atomic_is_lock_free(sizeof(T), ptr); }

    void store(T desired, memory_order m = memory_order_seq_cst) const noexcept {
        __atomic_store(ptr, addressof(desired), order(m));
    }
    T operator=(T desired) const noexcept {
        store(desired);
        return desired;
    }
    T load(memory_order m = memory_order_seq_cst) const noexcept {
        alignas(T) unsigned char buf[sizeof(T)];
        auto* out = reinterpret_cast<T*>(buf);
        __atomic_load(ptr, out, order(m));
        return *out;
    }
    operator T() const noexcept { return load(); }
    T exchange(T desired, memory_order m = memory_order_seq_cst) const noexcept {
        alignas(T) unsigned char buf[sizeof(T)];
        auto* out = reinterpret_cast<T*>(buf);
        __atomic_exchange(ptr, addressof(desired), out, order(m));
        return *out;
    }
    bool compare_exchange_weak(T& expected, T desired, memory_order success,
                               memory_order fail) const noexcept {
        return __atomic_compare_exchange(ptr, addressof(expected), addressof(desired), true,
                                         order(success), order(fail));
    }
    bool compare_exchange_strong(T& expected, T desired, memory_order success,
                                 memory_order fail) const noexcept {
        return __atomic_compare_exchange(ptr, addressof(expected), addressof(desired), false,
                                         order(success), order(fail));
    }
    bool compare_exchange_weak(T& expected, T desired,
                               memory_order m = memory_order_seq_cst) const noexcept {
        return compare_exchange_weak(expected, desired, m, failure(m));
    }
    bool compare_exchange_strong(T& expected, T desired,
                                 memory_order m = memory_order_seq_cst) const noexcept {
        return compare_exchange_strong(expected, desired, m, failure(m));
    }

    template <class U = T, enable_if_t<is_integral_v<U> && !is_same_v<U, bool>, int> = 0>
    // Waiting goes through std::atomic<T>, which has the layout of T, so that the libc++ wait
    // and notify functions see the same address.
    void wait(T old, memory_order m = memory_order_seq_cst) const noexcept {
        static_assert(sizeof(atomic<T>) == sizeof(T) && alignof(atomic<T>) == alignof(T));
        reinterpret_cast<const atomic<T>*>(ptr)->wait(old, m);
    }
    void notify_one() const noexcept { reinterpret_cast<atomic<T>*>(ptr)->notify_one(); }
    void notify_all() const noexcept { reinterpret_cast<atomic<T>*>(ptr)->notify_all(); }

    T fetch_add(T v, memory_order m = memory_order_seq_cst) const noexcept {
        return __atomic_fetch_add(ptr, v, order(m));
    }
    template <class U = T, enable_if_t<is_integral_v<U> && !is_same_v<U, bool>, int> = 0>
    T fetch_sub(T v, memory_order m = memory_order_seq_cst) const noexcept {
        return __atomic_fetch_sub(ptr, v, order(m));
    }
    template <class U = T, enable_if_t<is_integral_v<U> && !is_same_v<U, bool>, int> = 0>
    T fetch_and(T v, memory_order m = memory_order_seq_cst) const noexcept {
        return __atomic_fetch_and(ptr, v, order(m));
    }
    template <class U = T, enable_if_t<is_integral_v<U> && !is_same_v<U, bool>, int> = 0>
    T fetch_or(T v, memory_order m = memory_order_seq_cst) const noexcept {
        return __atomic_fetch_or(ptr, v, order(m));
    }
    template <class U = T, enable_if_t<is_integral_v<U> && !is_same_v<U, bool>, int> = 0>
    T fetch_xor(T v, memory_order m = memory_order_seq_cst) const noexcept {
        return __atomic_fetch_xor(ptr, v, order(m));
    }
};

} // namespace std

#endif
