# frozen_string_literal: true

require "ffi"

require_relative "imgui/version"
require_relative "imgui/errors"
require_relative "imgui/native"
require_relative "imgui/memory_pool"
require_relative "imgui/struct_value"
require_relative "imgui/value"
require_relative "imgui/fonts"
require_relative "imgui/io"
require_relative "imgui/style"
require_relative "imgui/draw_data"
require_relative "imgui/api"
require_relative "imgui/api_generated"
require_relative "imgui/widgets"
require_relative "imgui/layout"
require_relative "imgui/dsl"
require_relative "imgui/backends"
require_relative "imgui/backends/glfw"
require_relative "imgui/backends/opengl3"
require_relative "imgui/backends/sdl3"
require_relative "imgui/backends/wgpu"
require_relative "imgui/easy_loop"

module ImGui
end
