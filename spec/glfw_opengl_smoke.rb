# frozen_string_literal: true

begin
  gem "glfw-ruby"
  require "glfw"
rescue Gem::LoadError, LoadError => error
  raise if ENV["IMGUI_RUBY_REQUIRE_GLFW"] == "1"

  warn "GLFW/OpenGL smoke skipped: #{error.message}"
  exit 0
end

require "imgui"

GLFW.init
window = GLFW::Window.new(
  640,
  480,
  "imgui-ruby OpenGL smoke",
  visible: true,
  context_version_major: 3,
  context_version_minor: 2,
  opengl_profile: :core,
  opengl_forward_compat: true
)
window.make_context_current
GLFW.poll_events
context = ImGui.create_context
platform_initialized = false
renderer_initialized = false

begin
  io = ImGui.io
  io.ini_filename = nil
  io.fonts.add_font_default
  io.fonts.build
  platform_initialized = ImGui::Backends::Glfw.init_for_opengl(window)
  raise "GLFW backend initialization failed" unless platform_initialized

  renderer_initialized = ImGui::Backends::OpenGL3.init("#version 150")
  raise "OpenGL3 backend initialization failed" unless renderer_initialized

  2.times do
    GLFW.poll_events
    ImGui::Backends::OpenGL3.new_frame
    ImGui::Backends::Glfw.new_frame
    ImGui.new_frame
    ImGui.window("OpenGL") { ImGui.text("GLFW and OpenGL3 are active") }
    ImGui.render
  end
  ImGui::Backends::OpenGL3.render_draw_data
  window.swap_buffers

  unless ImGui.draw_data.total_vtx_count.positive?
    raise "OpenGL backend produced no vertices (display_size=#{ImGui.io.display_size.inspect})"
  end

  puts "GLFW/OpenGL3: rendered #{ImGui.draw_data.total_vtx_count} vertices"
ensure
  ImGui::Backends::OpenGL3.shutdown if renderer_initialized
  ImGui::Backends::Glfw.shutdown if platform_initialized
  ImGui.destroy_context(context) if context
  window&.destroy
  GLFW.terminate
end
