cmake_minimum_required(VERSION 3.15)
project(cimgui_ruby LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(IMGUI_RUBY_WITH_GLFW "Compile the Dear ImGui GLFW backend" OFF)
option(IMGUI_RUBY_WITH_OPENGL3 "Compile the Dear ImGui OpenGL3 backend" OFF)
option(IMGUI_RUBY_WITH_SDL3 "Compile the Dear ImGui SDL3 backend" OFF)
option(IMGUI_RUBY_WITH_IMPLOT "Compile the bundled ImPlot extension" ON)
option(IMGUI_RUBY_WITH_WGPU "Compile the Dear ImGui WebGPU backend" OFF)

get_filename_component(IMGUI_RUBY_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(CIMGUI_DIR "${IMGUI_RUBY_ROOT}/generator/vendor/cimgui")
set(IMGUI_DIR "${CIMGUI_DIR}/imgui")
set(CIMPLOT_DIR "${IMGUI_RUBY_ROOT}/generator/vendor/cimplot")
set(SDL_DIR "${IMGUI_RUBY_ROOT}/generator/vendor/sdl")
set(WEBGPU_HEADERS_DIR "${IMGUI_RUBY_ROOT}/generator/vendor")

if(NOT EXISTS "${CIMGUI_DIR}/cimgui.cpp")
  message(FATAL_ERROR "cimgui submodule is missing; run git submodule update --init --recursive")
endif()

set(IMGUI_RUBY_SOURCES
  "${CIMGUI_DIR}/cimgui.cpp"
  "${IMGUI_DIR}/imgui.cpp"
  "${IMGUI_DIR}/imgui_draw.cpp"
  "${IMGUI_DIR}/imgui_tables.cpp"
  "${IMGUI_DIR}/imgui_widgets.cpp"
  "${IMGUI_DIR}/imgui_demo.cpp"
)

set(IMGUI_RUBY_BACKEND_DEFINITIONS)
if(IMGUI_RUBY_WITH_IMPLOT)
  if(NOT EXISTS "${CIMPLOT_DIR}/cimplot.cpp")
    message(FATAL_ERROR "cimplot submodule is missing; run git submodule update --init --recursive")
  endif()
  list(APPEND IMGUI_RUBY_SOURCES
    "${CIMPLOT_DIR}/cimplot.cpp"
    "${CIMPLOT_DIR}/implot/implot.cpp"
    "${CIMPLOT_DIR}/implot/implot_demo.cpp"
    "${CIMPLOT_DIR}/implot/implot_items.cpp"
  )
endif()

if(IMGUI_RUBY_WITH_GLFW)
  list(APPEND IMGUI_RUBY_SOURCES
    "${CMAKE_CURRENT_LIST_DIR}/backend_function_bridge.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/glfw_vulkan_bridge.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/imgui_ruby_glfw.cpp"
    "${CIMGUI_DIR}/cimgui_impl.cpp"
  )
  list(APPEND IMGUI_RUBY_BACKEND_DEFINITIONS CIMGUI_USE_GLFW)
endif()

if(IMGUI_RUBY_WITH_OPENGL3)
  list(APPEND IMGUI_RUBY_SOURCES
    "${CIMGUI_DIR}/cimgui_impl.cpp"
    "${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp"
  )
  list(APPEND IMGUI_RUBY_BACKEND_DEFINITIONS CIMGUI_USE_OPENGL3)
endif()

if(IMGUI_RUBY_WITH_SDL3)
  if(NOT EXISTS "${SDL_DIR}/include/SDL3/SDL.h")
    message(FATAL_ERROR "SDL submodule is missing; run git submodule update --init --recursive")
  endif()
  list(APPEND IMGUI_RUBY_SOURCES
    "${CMAKE_CURRENT_LIST_DIR}/backend_function_bridge.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/imgui_ruby_sdl3.cpp"
    "${CIMGUI_DIR}/cimgui_impl.cpp"
  )
  list(APPEND IMGUI_RUBY_BACKEND_DEFINITIONS CIMGUI_USE_SDL3)
endif()

if(IMGUI_RUBY_WITH_WGPU)
  if(NOT EXISTS "${WEBGPU_HEADERS_DIR}/webgpu/webgpu.h")
    message(FATAL_ERROR "WebGPU headers submodule is missing; run git submodule update --init --recursive")
  endif()
  list(APPEND IMGUI_RUBY_SOURCES
    "${CMAKE_CURRENT_LIST_DIR}/imgui_ruby_wgpu.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/webgpu_function_bridge.cpp"
    "${IMGUI_DIR}/backends/imgui_impl_wgpu.cpp"
  )
  list(APPEND IMGUI_RUBY_BACKEND_DEFINITIONS IMGUI_IMPL_WEBGPU_BACKEND_WGPU)
endif()

list(REMOVE_DUPLICATES IMGUI_RUBY_SOURCES)
add_library(cimgui_ruby SHARED ${IMGUI_RUBY_SOURCES})
target_include_directories(cimgui_ruby PRIVATE
  "${CIMGUI_DIR}"
  "${IMGUI_DIR}"
  "${IMGUI_DIR}/backends"
  "${IMGUI_DIR}/examples/libs/glfw/include"
  "${CIMPLOT_DIR}"
  "${CIMPLOT_DIR}/implot"
  "${SDL_DIR}/include"
  "${WEBGPU_HEADERS_DIR}"
)
target_compile_definitions(cimgui_ruby PRIVATE
  IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
  IMGUI_IMPL_API=extern\ "C"
  ${IMGUI_RUBY_BACKEND_DEFINITIONS}
)

target_link_libraries(cimgui_ruby PRIVATE ${CMAKE_DL_LIBS})

set_target_properties(cimgui_ruby PROPERTIES OUTPUT_NAME cimgui_ruby)
install(TARGETS cimgui_ruby
  RUNTIME DESTINATION .
  LIBRARY DESTINATION .
  ARCHIVE DESTINATION .
)
