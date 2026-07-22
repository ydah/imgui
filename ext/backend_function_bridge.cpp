#include "backend_function_bridge.h"

#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace
{
std::mutex bridge_mutex;
std::unordered_map<std::string, void*> library_handles;
std::string bridge_error;

const std::vector<const char*>& required_functions(const std::string& backend)
{
    static const std::vector<const char*> glfw = {
        "glfwCreateStandardCursor", "glfwCreateWindow", "glfwCreateWindowSurface",
        "glfwDestroyCursor", "glfwDestroyWindow", "glfwFocusWindow",
        "glfwGetClipboardString", "glfwGetCursorPos", "glfwGetError",
        "glfwGetFramebufferSize", "glfwGetGamepadState", "glfwGetInputMode",
        "glfwGetJoystickAxes", "glfwGetJoystickButtons", "glfwGetKey", "glfwGetKeyName",
        "glfwGetMonitorContentScale", "glfwGetMonitorPos", "glfwGetMonitorWorkarea",
        "glfwGetMonitors", "glfwGetTime", "glfwGetVideoMode", "glfwGetWindowAttrib",
        "glfwGetWindowPos", "glfwGetWindowSize", "glfwMakeContextCurrent",
        "glfwSetCharCallback", "glfwSetClipboardString", "glfwSetCursor",
        "glfwSetCursorEnterCallback", "glfwSetCursorPos", "glfwSetCursorPosCallback",
        "glfwSetErrorCallback", "glfwSetInputMode", "glfwSetKeyCallback",
        "glfwSetMonitorCallback", "glfwSetMouseButtonCallback", "glfwSetScrollCallback",
        "glfwSetWindowAttrib", "glfwSetWindowCloseCallback", "glfwSetWindowFocusCallback",
        "glfwSetWindowOpacity", "glfwSetWindowPos", "glfwSetWindowPosCallback",
        "glfwSetWindowSize", "glfwSetWindowSizeCallback", "glfwSetWindowTitle",
        "glfwShowWindow", "glfwSwapBuffers", "glfwSwapInterval", "glfwWindowHint",
#if defined(_WIN32)
        "glfwGetWin32Window",
#elif defined(__APPLE__)
        "glfwGetCocoaWindow",
#endif
    };
    static const std::vector<const char*> sdl3 = {
        "SDL_CaptureMouse", "SDL_CloseGamepad", "SDL_CreateSystemCursor", "SDL_CreateWindow",
        "SDL_DestroyCursor", "SDL_DestroyWindow", "SDL_GL_CreateContext", "SDL_GL_DestroyContext",
        "SDL_GL_GetCurrentContext", "SDL_GL_MakeCurrent", "SDL_GL_SetAttribute",
        "SDL_GL_SetSwapInterval", "SDL_GL_SwapWindow", "SDL_GetClipboardText",
        "SDL_GetCurrentVideoDriver", "SDL_GetDisplayBounds", "SDL_GetDisplayContentScale",
        "SDL_GetDisplayUsableBounds", "SDL_GetDisplays", "SDL_GetGamepadAxis",
        "SDL_GetGamepadButton", "SDL_GetGamepads", "SDL_GetGlobalMouseState",
        "SDL_GetKeyboardFocus", "SDL_GetPerformanceCounter", "SDL_GetPerformanceFrequency",
        "SDL_GetPointerProperty", "SDL_GetWindowFlags", "SDL_GetWindowFromID", "SDL_GetWindowID",
        "SDL_GetWindowPosition", "SDL_GetWindowProperties", "SDL_GetWindowRelativeMouseMode",
        "SDL_GetWindowSize", "SDL_GetWindowSizeInPixels", "SDL_HideCursor", "SDL_OpenGamepad",
        "SDL_OpenURL", "SDL_RaiseWindow", "SDL_SetClipboardText", "SDL_SetCursor", "SDL_SetHint",
        "SDL_SetTextInputArea", "SDL_SetWindowOpacity", "SDL_SetWindowParent",
        "SDL_SetWindowPosition", "SDL_SetWindowSize", "SDL_SetWindowTitle", "SDL_ShowCursor",
        "SDL_ShowWindow", "SDL_StartTextInput", "SDL_StopTextInput", "SDL_Vulkan_CreateSurface",
        "SDL_WarpMouseGlobal", "SDL_WarpMouseInWindow", "SDL_free", "SDL_strdup",
    };
    static const std::vector<const char*> empty;

    if (backend == "GLFW")
        return glfw;
    if (backend == "SDL3")
        return sdl3;
    return empty;
}

void set_error(const std::string& message)
{
    bridge_error = message;
}

void* open_library(const char* path)
{
#if defined(_WIN32)
    HMODULE handle = LoadLibraryA(path);
    if (handle == nullptr)
        set_error("LoadLibrary failed for " + std::string(path) + " (error " + std::to_string(GetLastError()) + ")");
    return reinterpret_cast<void*>(handle);
#else
    dlerror();
    void* handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL);
    if (handle == nullptr)
    {
        const char* error = dlerror();
        set_error(error != nullptr ? error : "dlopen failed for " + std::string(path));
    }
    return handle;
#endif
}

void* find_symbol(void* handle, const char* name)
{
#if defined(_WIN32)
    return reinterpret_cast<void*>(GetProcAddress(reinterpret_cast<HMODULE>(handle), name));
#else
    dlerror();
    return dlsym(handle, name);
#endif
}
} // namespace

extern "C" IMGUI_RUBY_EXPORT bool imgui_ruby_backend_load_library(const char* backend, const char* path)
{
    if (backend == nullptr || path == nullptr || backend[0] == '\0' || path[0] == '\0')
        return false;

    std::lock_guard<std::mutex> lock(bridge_mutex);
    if (library_handles.find(backend) != library_handles.end())
        return true;

    void* handle = open_library(path);
    if (handle == nullptr)
        return false;

    library_handles.emplace(backend, handle);
    bridge_error.clear();
    return true;
}

extern "C" IMGUI_RUBY_EXPORT bool imgui_ruby_backend_library_ready(const char* backend)
{
    if (backend == nullptr)
        return false;

    std::lock_guard<std::mutex> lock(bridge_mutex);
    return library_handles.find(backend) != library_handles.end();
}

extern "C" IMGUI_RUBY_EXPORT bool imgui_ruby_backend_has_function(const char* backend, const char* name)
{
    return imgui_ruby_backend_resolve_function(backend, name) != nullptr;
}

extern "C" IMGUI_RUBY_EXPORT size_t imgui_ruby_backend_required_function_count(const char* backend)
{
    return backend != nullptr ? required_functions(backend).size() : 0;
}

extern "C" IMGUI_RUBY_EXPORT const char* imgui_ruby_backend_required_function_name(
    const char* backend,
    size_t index)
{
    if (backend == nullptr)
        return nullptr;
    const auto& functions = required_functions(backend);
    return index < functions.size() ? functions[index] : nullptr;
}

extern "C" IMGUI_RUBY_EXPORT const char* imgui_ruby_backend_library_error()
{
    std::lock_guard<std::mutex> lock(bridge_mutex);
    return bridge_error.c_str();
}

void* imgui_ruby_backend_resolve_function(const char* backend, const char* name)
{
    if (backend == nullptr || name == nullptr)
        return nullptr;

    std::lock_guard<std::mutex> lock(bridge_mutex);
    auto library = library_handles.find(backend);
    if (library == library_handles.end())
    {
        set_error(std::string(backend) + " runtime library is not loaded");
        return nullptr;
    }

    void* address = find_symbol(library->second, name);
    if (address == nullptr)
        set_error(std::string(backend) + " runtime library does not export " + name);
    return address;
}
