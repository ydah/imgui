# frozen_string_literal: true

begin
  require "sdl3"
rescue LoadError => error
  raise if ENV["IMGUI_RUBY_REQUIRE_SDL3"] == "1"

  warn "SDL3 smoke skipped: #{error.message}"
  exit 0
end

require "imgui"

SDL3.init(SDL3::INIT_VIDEO | SDL3::INIT_GAMEPAD)
window = SDL3::Window.new("imgui-ruby SDL3 smoke", 640, 480, SDL3::Window::HIDDEN)
context = ImGui.create_context
initialized = false

begin
  io = ImGui.io
  io.ini_filename = nil
  io.fonts.add_font_default
  io.fonts.build

  initialized = ImGui::Backends::SDL3.init_for_other(window.ptr)
  raise "SDL3 backend initialization failed" unless initialized

  ImGui::Backends::SDL3.set_gamepad_mode(:auto_first)
  ImGui::Backends::SDL3.new_frame
  ImGui.new_frame
  ImGui.window("SDL3") { ImGui.text("SDL3 backend is active") }
  ImGui.render

  raise "SDL3 backend produced no draw data" unless ImGui.draw_data

  puts "SDL3: backend frame completed"
ensure
  ImGui::Backends::SDL3.shutdown if initialized
  ImGui.destroy_context(context) if context
  window&.destroy
  SDL3.quit
end
