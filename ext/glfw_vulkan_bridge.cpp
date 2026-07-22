#include <GLFW/glfw3.h>

#include "backend_function_bridge.h"

extern "C" int glfwCreateWindowSurface(
    void* instance,
    GLFWwindow* window,
    const void* allocator,
    void* surface)
{
    using Function = int (*)(void*, GLFWwindow*, const void*, void*);
    static auto function = imgui_ruby_backend_function<Function>("GLFW", "glfwCreateWindowSurface");
    return function(instance, window, allocator, surface);
}
