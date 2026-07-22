#include <GLFW/glfw3.h>

#if defined(_WIN32)
#define GLFW_EXPOSE_NATIVE_WIN32
#include <GLFW/glfw3native.h>
#elif defined(__APPLE__)
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3native.h>
#endif

#include "backend_function_bridge.h"

#define IMGUI_RUBY_GLFW(function_name, ...)                                                       \
    IMGUI_RUBY_BACKEND_CALL("GLFW", function_name, __VA_ARGS__)

#define glfwCreateStandardCursor(...) IMGUI_RUBY_GLFW(glfwCreateStandardCursor, __VA_ARGS__)
#define glfwCreateWindow(...) IMGUI_RUBY_GLFW(glfwCreateWindow, __VA_ARGS__)
#define glfwDestroyCursor(...) IMGUI_RUBY_GLFW(glfwDestroyCursor, __VA_ARGS__)
#define glfwDestroyWindow(...) IMGUI_RUBY_GLFW(glfwDestroyWindow, __VA_ARGS__)
#define glfwFocusWindow(...) IMGUI_RUBY_GLFW(glfwFocusWindow, __VA_ARGS__)
#define glfwGetClipboardString(...) IMGUI_RUBY_GLFW(glfwGetClipboardString, __VA_ARGS__)
#if defined(__APPLE__)
#define glfwGetCocoaWindow(...) IMGUI_RUBY_GLFW(glfwGetCocoaWindow, __VA_ARGS__)
#endif
#define glfwGetCursorPos(...) IMGUI_RUBY_GLFW(glfwGetCursorPos, __VA_ARGS__)
#define glfwGetError(...) IMGUI_RUBY_GLFW(glfwGetError, __VA_ARGS__)
#define glfwGetFramebufferSize(...) IMGUI_RUBY_GLFW(glfwGetFramebufferSize, __VA_ARGS__)
#define glfwGetGamepadState(...) IMGUI_RUBY_GLFW(glfwGetGamepadState, __VA_ARGS__)
#define glfwGetInputMode(...) IMGUI_RUBY_GLFW(glfwGetInputMode, __VA_ARGS__)
#define glfwGetJoystickAxes(...) IMGUI_RUBY_GLFW(glfwGetJoystickAxes, __VA_ARGS__)
#define glfwGetJoystickButtons(...) IMGUI_RUBY_GLFW(glfwGetJoystickButtons, __VA_ARGS__)
#define glfwGetKey(...) IMGUI_RUBY_GLFW(glfwGetKey, __VA_ARGS__)
#define glfwGetKeyName(...) IMGUI_RUBY_GLFW(glfwGetKeyName, __VA_ARGS__)
#define glfwGetMonitorContentScale(...) IMGUI_RUBY_GLFW(glfwGetMonitorContentScale, __VA_ARGS__)
#define glfwGetMonitorPos(...) IMGUI_RUBY_GLFW(glfwGetMonitorPos, __VA_ARGS__)
#define glfwGetMonitorWorkarea(...) IMGUI_RUBY_GLFW(glfwGetMonitorWorkarea, __VA_ARGS__)
#define glfwGetMonitors(...) IMGUI_RUBY_GLFW(glfwGetMonitors, __VA_ARGS__)
#define glfwGetTime(...) IMGUI_RUBY_GLFW(glfwGetTime, __VA_ARGS__)
#define glfwGetVideoMode(...) IMGUI_RUBY_GLFW(glfwGetVideoMode, __VA_ARGS__)
#if defined(_WIN32)
#define glfwGetWin32Window(...) IMGUI_RUBY_GLFW(glfwGetWin32Window, __VA_ARGS__)
#endif
#define glfwGetWindowAttrib(...) IMGUI_RUBY_GLFW(glfwGetWindowAttrib, __VA_ARGS__)
#define glfwGetWindowPos(...) IMGUI_RUBY_GLFW(glfwGetWindowPos, __VA_ARGS__)
#define glfwGetWindowSize(...) IMGUI_RUBY_GLFW(glfwGetWindowSize, __VA_ARGS__)
#define glfwMakeContextCurrent(...) IMGUI_RUBY_GLFW(glfwMakeContextCurrent, __VA_ARGS__)
#define glfwSetCharCallback(...) IMGUI_RUBY_GLFW(glfwSetCharCallback, __VA_ARGS__)
#define glfwSetClipboardString(...) IMGUI_RUBY_GLFW(glfwSetClipboardString, __VA_ARGS__)
#define glfwSetCursor(...) IMGUI_RUBY_GLFW(glfwSetCursor, __VA_ARGS__)
#define glfwSetCursorEnterCallback(...) IMGUI_RUBY_GLFW(glfwSetCursorEnterCallback, __VA_ARGS__)
#define glfwSetCursorPos(...) IMGUI_RUBY_GLFW(glfwSetCursorPos, __VA_ARGS__)
#define glfwSetCursorPosCallback(...) IMGUI_RUBY_GLFW(glfwSetCursorPosCallback, __VA_ARGS__)
#define glfwSetErrorCallback(...) IMGUI_RUBY_GLFW(glfwSetErrorCallback, __VA_ARGS__)
#define glfwSetInputMode(...) IMGUI_RUBY_GLFW(glfwSetInputMode, __VA_ARGS__)
#define glfwSetKeyCallback(...) IMGUI_RUBY_GLFW(glfwSetKeyCallback, __VA_ARGS__)
#define glfwSetMonitorCallback(...) IMGUI_RUBY_GLFW(glfwSetMonitorCallback, __VA_ARGS__)
#define glfwSetMouseButtonCallback(...) IMGUI_RUBY_GLFW(glfwSetMouseButtonCallback, __VA_ARGS__)
#define glfwSetScrollCallback(...) IMGUI_RUBY_GLFW(glfwSetScrollCallback, __VA_ARGS__)
#define glfwSetWindowAttrib(...) IMGUI_RUBY_GLFW(glfwSetWindowAttrib, __VA_ARGS__)
#define glfwSetWindowCloseCallback(...) IMGUI_RUBY_GLFW(glfwSetWindowCloseCallback, __VA_ARGS__)
#define glfwSetWindowFocusCallback(...) IMGUI_RUBY_GLFW(glfwSetWindowFocusCallback, __VA_ARGS__)
#define glfwSetWindowOpacity(...) IMGUI_RUBY_GLFW(glfwSetWindowOpacity, __VA_ARGS__)
#define glfwSetWindowPos(...) IMGUI_RUBY_GLFW(glfwSetWindowPos, __VA_ARGS__)
#define glfwSetWindowPosCallback(...) IMGUI_RUBY_GLFW(glfwSetWindowPosCallback, __VA_ARGS__)
#define glfwSetWindowSize(...) IMGUI_RUBY_GLFW(glfwSetWindowSize, __VA_ARGS__)
#define glfwSetWindowSizeCallback(...) IMGUI_RUBY_GLFW(glfwSetWindowSizeCallback, __VA_ARGS__)
#define glfwSetWindowTitle(...) IMGUI_RUBY_GLFW(glfwSetWindowTitle, __VA_ARGS__)
#define glfwShowWindow(...) IMGUI_RUBY_GLFW(glfwShowWindow, __VA_ARGS__)
#define glfwSwapBuffers(...) IMGUI_RUBY_GLFW(glfwSwapBuffers, __VA_ARGS__)
#define glfwSwapInterval(...) IMGUI_RUBY_GLFW(glfwSwapInterval, __VA_ARGS__)
#define glfwWindowHint(...) IMGUI_RUBY_GLFW(glfwWindowHint, __VA_ARGS__)

#include "../generator/vendor/cimgui/imgui/backends/imgui_impl_glfw.cpp"
