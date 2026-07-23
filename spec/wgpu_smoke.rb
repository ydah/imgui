# frozen_string_literal: true

require "imgui"
require "wgpu"

imgui_context = ImGui.create_context
io = ImGui.io
io.ini_filename = nil
io.display_size = [320, 240]
io.delta_time = 1.0 / 60
io.fonts.add_font_default
io.fonts.build

library = WGPU::Native.ffi_libraries.first
ImGui::Backends::WGPU.__send__(:configure_function_table!, library)
puts "WGPU: validated #{ImGui::Native.imgui_ruby_wgpu_required_function_count} functions"

instance = WGPU::Instance.new
begin
  adapter = instance.request_adapter
rescue WGPU::AdapterError => error
  raise if ENV["IMGUI_RUBY_REQUIRE_WGPU"] == "1"

  warn "WGPU smoke skipped: #{error.message.lines.first.strip}"
  instance.release
  ImGui.destroy_context(imgui_context)
  exit 0
end
device = adapter.request_device(label: "imgui-ruby smoke")
format = WGPU::Native::TextureFormat[:rgba8_unorm]

unless ImGui::Backends::WGPU.init(
  device: device,
  queue: device.queue,
  render_target_format: format
)
  raise "failed to initialize the WGPU backend"
end

texture = device.create_texture(
  label: "imgui-ruby target",
  size: { width: 320, height: 240, depth_or_array_layers: 1 },
  format: format,
  usage: :render_attachment
)
view_handle = WGPU::Native.wgpuTextureCreateView(texture.handle, nil)
raise "failed to create the WGPU target view" if view_handle.null?

view = WGPU::TextureView.from_handle(view_handle)
encoder = device.create_command_encoder(label: "imgui-ruby encoder")

2.times do
  ImGui::Backends::WGPU.new_frame
  ImGui.new_frame
  ImGui.window("WGPU") { ImGui.text("function-table bridge") }
  ImGui.render
end

unless ImGui.draw_data.total_vertex_count.positive?
  raise "WGPU backend produced no vertices"
end

unless ImGui::Backends::WGPU.render_draw_data(ImGui.draw_data, encoder, view)
  raise "failed to encode ImGui WGPU draw data"
end

command_buffer = encoder.finish
device.queue.submit([command_buffer])
puts "WGPU: rendered #{ImGui.draw_data.total_vertex_count} vertices"

ImGui::Backends::WGPU.shutdown
command_buffer.release
encoder.release
view.release
texture.destroy
texture.release
device.queue.release
device.destroy
device.release
adapter.release
instance.release
ImGui.destroy_context(imgui_context)
