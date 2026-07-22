cmake_minimum_required(VERSION 3.15)
project(cimgui_ruby LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(IMGUI_RUBY_WITH_GLFW "Compile the Dear ImGui GLFW backend" OFF)
option(IMGUI_RUBY_WITH_OPENGL3 "Compile the Dear ImGui OpenGL3 backend" OFF)
option(IMGUI_RUBY_WITH_SDL3 "Compile the Dear ImGui SDL3 backend" OFF)

get_filename_component(IMGUI_RUBY_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(CIMGUI_DIR "${IMGUI_RUBY_ROOT}/generator/vendor/cimgui")
set(IMGUI_DIR "${CIMGUI_DIR}/imgui")

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
if(IMGUI_RUBY_WITH_GLFW)
  list(APPEND IMGUI_RUBY_SOURCES
    "${CIMGUI_DIR}/cimgui_impl.cpp"
    "${IMGUI_DIR}/backends/imgui_impl_glfw.cpp"
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
  list(APPEND IMGUI_RUBY_SOURCES
    "${CIMGUI_DIR}/cimgui_impl.cpp"
    "${IMGUI_DIR}/backends/imgui_impl_sdl3.cpp"
  )
  list(APPEND IMGUI_RUBY_BACKEND_DEFINITIONS CIMGUI_USE_SDL3)
endif()

list(REMOVE_DUPLICATES IMGUI_RUBY_SOURCES)
add_library(cimgui_ruby SHARED ${IMGUI_RUBY_SOURCES})
target_include_directories(cimgui_ruby PRIVATE
  "${CIMGUI_DIR}"
  "${IMGUI_DIR}"
  "${IMGUI_DIR}/backends"
  "${IMGUI_DIR}/examples/libs/glfw/include"
)
target_compile_definitions(cimgui_ruby PRIVATE
  IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
  IMGUI_IMPL_API=extern\ "C"
  ${IMGUI_RUBY_BACKEND_DEFINITIONS}
)

if(APPLE AND (IMGUI_RUBY_WITH_GLFW OR IMGUI_RUBY_WITH_OPENGL3))
  target_link_options(cimgui_ruby PRIVATE "-undefined" "dynamic_lookup")
endif()

set_target_properties(cimgui_ruby PROPERTIES OUTPUT_NAME cimgui_ruby)
install(TARGETS cimgui_ruby
  RUNTIME DESTINATION .
  LIBRARY DESTINATION .
  ARCHIVE DESTINATION .
)
