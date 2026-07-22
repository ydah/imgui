#pragma once

#include <cstdio>
#include <cstdlib>

#if defined(_WIN32)
#define IMGUI_RUBY_EXPORT __declspec(dllexport)
#else
#define IMGUI_RUBY_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {
IMGUI_RUBY_EXPORT bool imgui_ruby_backend_load_library(const char* backend, const char* path);
IMGUI_RUBY_EXPORT bool imgui_ruby_backend_library_ready(const char* backend);
IMGUI_RUBY_EXPORT bool imgui_ruby_backend_has_function(const char* backend, const char* name);
IMGUI_RUBY_EXPORT size_t imgui_ruby_backend_required_function_count(const char* backend);
IMGUI_RUBY_EXPORT const char* imgui_ruby_backend_required_function_name(const char* backend, size_t index);
IMGUI_RUBY_EXPORT const char* imgui_ruby_backend_library_error();
}

void* imgui_ruby_backend_resolve_function(const char* backend, const char* name);

template <typename Function>
Function imgui_ruby_backend_function(const char* backend, const char* name)
{
    void* address = imgui_ruby_backend_resolve_function(backend, name);
    if (address == nullptr)
    {
        std::fprintf(stderr, "imgui-ruby: unresolved %s function %s\n", backend, name);
        std::abort();
    }
    return reinterpret_cast<Function>(address);
}

#define IMGUI_RUBY_BACKEND_CALL(backend, function_name, ...)                                      \
    ([]() -> decltype(&function_name) {                                                           \
        static auto function = imgui_ruby_backend_function<decltype(&function_name)>(             \
            backend, #function_name);                                                             \
        return function;                                                                          \
    }())(__VA_ARGS__)
