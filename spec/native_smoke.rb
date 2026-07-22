# frozen_string_literal: true

require "imgui"
require "imgui/plot"

layout_sizes = [
  ImGui::Native::ImGuiIO.size,
  ImGui::Native::ImGuiStyle.size,
  ImGui::Native::ImVec2.size,
  ImGui::Native::ImVec4.size,
  ImGui::Native::ImDrawVert.size,
  ImGui::Native.find_type(:ImDrawIdx).size
]
unless ImGui::Native.igDebugCheckVersionAndDataLayout(ImGui.version_string, *layout_sizes)
  raise "generated FFI struct layouts do not match Dear ImGui"
end

context = ImGui.create_context
plot_context = ImPlot.create_context
io = ImGui.io
io.ini_filename = nil
io.display_size = [1280, 720]
io.delta_time = 1.0 / 60
io.fonts.add_font_default
raise "failed to build the font atlas" unless io.fonts.build

2.times do
  ImGui.new_frame
  ImGui.window("headless") do
    ImGui.text("native smoke 100%")
    ImPlot.plot("plot") { ImPlot.plot_line("series", [1.0, 3.0, 2.0]) }
  end
  ImGui.render
end

draw_data = ImGui.draw_data
raise "draw data is invalid" unless draw_data&.valid?
raise "headless frame produced no vertices" unless draw_data.total_vertex_count.positive?

puts "Dear ImGui #{ImGui.version_string} + ImPlot: #{draw_data.total_vertex_count} vertices"
ImPlot.destroy_context(plot_context)
ImGui.destroy_context(context)
