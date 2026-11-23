// SPDX-FileCopyrightText: 2022 yuzu Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later
//
// C++20 library features that older libc++ versions (Xcode 15's, and clang 16's) lack, for
// code written against a newer one. Force-included into every C++ translation unit by the
// MacPorts port; each part is only used when the standard library does not have the feature.
//
// - std::jthread, std::stop_token, std::stop_source and std::stop_callback, and the stop_token
//   overloads of std::condition_variable_any. The classes are yuzu's polyfill
//   (src/common/polyfill_thread.h in yuzu 0.1734); the condition_variable_any wrapper wakes
//   waiters the same way yuzu's Common::CondvarWait does.
// - operator<=> for std::array and std::hash<std::filesystem::path> (libc++ 17).
// - std::atomic_ref (libc++ 19), on the compiler's __atomic builtins.

#pragma once

#include <version>

#if defined(__cplusplus) && __cplusplus >= 202002L && !defined(__cpp_lib_jthread)

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <thread>
#include <type_traits>
#include <utility>

namespace std {
namespace polyfill {

using stop_state_callback = size_t;

class stop_state {
public:
    stop_state() = default;
    ~stop_state() = default;

    bool request_stop() {
        unique_lock lk{m_lock};

        if (m_stop_requested) {
            // Already set, nothing to do.
            return false;
        }

        // Mark stop requested.
        m_stop_requested = true;

        while (!m_callbacks.empty()) {
            // Get an iterator to the first element.
            const auto it = m_callbacks.begin();

            // Move the callback function out of the map.
            function<void()> f;
            swap(it->second, f);

            // Erase the now-empty map element.
            m_callbacks.erase(it);

            // Run the callback.
            if (f) {
                f();
            }
        }

        return true;
    }

    bool stop_requested() const {
        unique_lock lk{m_lock};
        return m_stop_requested;
    }

    stop_state_callback insert_callback(function<void()> f) {
        unique_lock lk{m_lock};

        if (m_stop_requested) {
            // Stop already requested. Don't insert anything,
            // just run the callback synchronously.
            if (f) {
                f();
            }
            return 0;
        }

        // Insert the callback.
        stop_state_callback ret = ++m_next_callback;
        m_callbacks.emplace(ret, std::move(f));
        return ret;
    }

    void remove_callback(stop_state_callback cb) {
        unique_lock lk{m_lock};
        m_callbacks.erase(cb);
    }

private:
    mutable recursive_mutex m_lock;
    map<stop_state_callback, function<void()>> m_callbacks;
    stop_state_callback m_next_callback{0};
    bool m_stop_requested{false};
};

} // namespace polyfill

class stop_token;
class stop_source;
struct nostopstate_t {
    explicit nostopstate_t() = default;
};
inline constexpr nostopstate_t nostopstate{};

template <class Callback>
class stop_callback;

class stop_token {
public:
    stop_token() noexcept = default;

    stop_token(const stop_token&) noexcept = default;
    stop_token(stop_token&&) noexcept = default;
    stop_token& operator=(const stop_token&) noexcept = default;
    stop_token& operator=(stop_token&&) noexcept = default;
    ~stop_token() = default;

    void swap(stop_token& other) noexcept {
        m_stop_state.swap(other.m_stop_state);
    }

    [[nodiscard]] bool stop_requested() const noexcept {
        return m_stop_state && m_stop_state->stop_requested();
    }
    [[nodiscard]] bool stop_possible() const noexcept {
        return m_stop_state != nullptr;
    }

private:
    friend class stop_source;
    template <typename Callback>
    friend class stop_callback;
    stop_token(shared_ptr<polyfill::stop_state> stop_state) : m_stop_state(std::move(stop_state)) {}

private:
    shared_ptr<polyfill::stop_state> m_stop_state;
};

class stop_source {
public:
    stop_source() : m_stop_state(make_shared<polyfill::stop_state>()) {}
    explicit stop_source(nostopstate_t) noexcept {}

    stop_source(const stop_source&) noexcept = default;
    stop_source(stop_source&&) noexcept = default;
    stop_source& operator=(const stop_source&) noexcept = default;
    stop_source& operator=(stop_source&&) noexcept = default;
    ~stop_source() = default;
    void swap(stop_source& other) noexcept {
        m_stop_state.swap(other.m_stop_state);
    }

    [[nodiscard]] stop_token get_token() const noexcept {
        return stop_token(m_stop_state);
    }
    [[nodiscard]] bool stop_possible() const noexcept {
        return m_stop_state != nullptr;
    }
    [[nodiscard]] bool stop_requested() const noexcept {
        return m_stop_state && m_stop_state->stop_requested();
    }
    bool request_stop() noexcept {
        return m_stop_state && m_stop_state->request_stop();
    }

private:
    friend class jthread;
    explicit stop_source(shared_ptr<polyfill::stop_state> stop_state)
        : m_stop_state(std::move(stop_state)) {}

private:
    shared_ptr<polyfill::stop_state> m_stop_state;
};

template <typename Callback>
class stop_callback {
    static_assert(is_nothrow_destructible_v<Callback>);
    static_assert(is_invocable_v<Callback>);

public:
    using callback_type = Callback;

    template <typename C>
        requires constructible_from<Callback, C>
    explicit stop_callback(const stop_token& st,
                           C&& cb) noexcept(is_nothrow_constructible_v<Callback, C>)
        : m_stop_state(st.m_stop_state) {
        if (m_stop_state) {
            m_callback = m_stop_state->insert_callback(std::move(cb));
        }
    }
    template <typename C>
        requires constructible_from<Callback, C>
    explicit stop_callback(stop_token&& st,
                           C&& cb) noexcept(is_nothrow_constructible_v<Callback, C>)
        : m_stop_state(std::move(st.m_stop_state)) {
        if (m_stop_state) {
            m_callback = m_stop_state->insert_callback(std::move(cb));
        }
    }
    ~stop_callback() {
        if (m_stop_state && m_callback) {
            m_stop_state->remove_callback(m_callback);
        }
    }

    stop_callback(const stop_callback&) = delete;
    stop_callback(stop_callback&&) = delete;
    stop_callback& operator=(const stop_callback&) = delete;
    stop_callback& operator=(stop_callback&&) = delete;

private:
    shared_ptr<polyfill::stop_state> m_stop_state;
    polyfill::stop_state_callback m_callback;
};

template <typename Callback>
stop_callback(stop_token, Callback) -> stop_callback<Callback>;

class jthread {
public:
    using id = thread::id;
    using native_handle_type = thread::native_handle_type;

    jthread() noexcept = default;

    template <typename F, typename... Args,
              typename = enable_if_t<!is_same_v<remove_cvref_t<F>, jthread>>>
    explicit jthread(F&& f, Args&&... args)
        : m_stop_state(make_shared<polyfill::stop_state>()),
          m_thread(make_thread(std::forward<F>(f), std::forward<Args>(args)...)) {}

    ~jthread() {
        if (joinable()) {
            request_stop();
            join();
        }
    }

    jthread(const jthread&) = delete;
    jthread(jthread&&) noexcept = default;
    jthread& operator=(const jthread&) = delete;

    jthread& operator=(jthread&& other) noexcept {
        m_thread.swap(other.m_thread);
        m_stop_state.swap(other.m_stop_state);
        return *this;
    }

    void swap(jthread& other) noexcept {
        m_thread.swap(other.m_thread);
        m_stop_state.swap(other.m_stop_state);
    }
    [[nodiscard]] bool joinable() const noexcept {
        return m_thread.joinable();
    }
    void join() {
        m_thread.join();
    }
    void detach() {
        m_thread.detach();
        m_stop_state.reset();
    }

    [[nodiscard]] id get_id() const noexcept {
        return m_thread.get_id();
    }
    [[nodiscard]] native_handle_type native_handle() {
        return m_thread.native_handle();
    }
    [[nodiscard]] stop_source get_stop_source() noexcept {
        return stop_source(m_stop_state);
    }
    [[nodiscard]] stop_token get_stop_token() const noexcept {
        return stop_source(m_stop_state).get_token();
    }
    bool request_stop() noexcept {
        return get_stop_source().request_stop();
    }
    [[nodiscard]] static unsigned int hardware_concurrency() noexcept {
        return thread::hardware_concurrency();
    }

private:
    template <typename F, typename... Args>
    thread make_thread(F&& f, Args&&... args) {
        if constexpr (is_invocable_v<decay_t<F>, stop_token, decay_t<Args>...>) {
            return thread(std::forward<F>(f), get_stop_token(), std::forward<Args>(args)...);
        } else {
            return thread(std::forward<F>(f), std::forward<Args>(args)...);
        }
    }

    shared_ptr<polyfill::stop_state> m_stop_state;
    thread m_thread;
};

} // namespace std

namespace std {
namespace macports_polyfill {

// std::condition_variable_any with the C++20 stop_token overloads of wait, wait_until and
// wait_for. A stop request takes the waiter's mutex before notifying, so it cannot slip in
// between the waiter's predicate check and its wait.
class condition_variable_any : public ::std::condition_variable_any {
    using base = ::std::condition_variable_any;

public:
    using base::base;
    using base::wait;
    using base::wait_for;
    using base::wait_until;

    template <class Lock, class Predicate>
    bool wait(Lock& lock, stop_token stoken, Predicate pred) {
        if (stoken.stop_requested()) {
            return pred();
        }
        stop_callback callback(stoken, [this, &lock] {
            { scoped_lock relock{*lock.mutex()}; }
            this->notify_all();
        });
        base::wait(lock, [&] { return pred() || stoken.stop_requested(); });
        return pred();
    }

    template <class Lock, class Clock, class Duration, class Predicate>
    bool wait_until(Lock& lock, stop_token stoken,
                    const chrono::time_point<Clock, Duration>& abs_time, Predicate pred) {
        if (stoken.stop_requested()) {
            return pred();
        }
        stop_callback callback(stoken, [this, &lock] {
            { scoped_lock relock{*lock.mutex()}; }
            this->notify_all();
        });
        base::wait_until(lock, abs_time, [&] { return pred() || stoken.stop_requested(); });
        return pred();
    }

    template <class Lock, class Rep, class Period, class Predicate>
    bool wait_for(Lock& lock, stop_token stoken, const chrono::duration<Rep, Period>& rel_time,
                  Predicate pred) {
        return wait_until(lock, std::move(stoken), chrono::steady_clock::now() + rel_time,
                          std::move(pred));
    }
};

} // namespace macports_polyfill
} // namespace std

// Every later std::condition_variable_any is the wrapper. <condition_variable> is the only
// libc++ header that names the class, and it has been included above.
#define condition_variable_any macports_polyfill::condition_variable_any

#endif

#if defined(__cplusplus) && __cplusplus >= 202002L && defined(_LIBCPP_VERSION) && \
    _LIBCPP_VERSION < 170000

#include <array>
#include <compare>
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

template <class T, size_t N>
constexpr auto operator<=>(const array<T, N>& lhs, const array<T, N>& rhs)
    -> compare_three_way_result_t<T> {
    for (size_t i = 0; i < N; ++i) {
        if (auto order = lhs[i] <=> rhs[i]; order != 0) {
            return order;
        }
    }
    return compare_three_way_result_t<T>(strong_ordering::equal);
}

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
