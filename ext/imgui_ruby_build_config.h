#pragma once

// Keep backend declarations compatible with cimgui's exported C ABI on every
// translation unit, including vendor sources compiled directly by CMake.
#if !defined(IMGUI_IMPL_API)
#if defined(_WIN32)
#define IMGUI_IMPL_API extern "C" __declspec(dllexport)
#else
#define IMGUI_IMPL_API extern "C" __attribute__((visibility("default")))
#endif
#endif

// GLFW includes the system OpenGL header by default, but the bundled backend
// uses Dear ImGui's own OpenGL loader and does not require that header.
#if !defined(GLFW_INCLUDE_NONE)
#define GLFW_INCLUDE_NONE
#endif
