#include "imgui.h"
#include "backends/imgui_impl_wgpu.h"

#include <webgpu/webgpu.h>

#if defined(_WIN32)
#define IMGUI_RUBY_EXPORT __declspec(dllexport)
#else
#define IMGUI_RUBY_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {

IMGUI_RUBY_EXPORT bool imgui_ruby_wgpu_init(
    void* device,
    int frames_in_flight,
    int render_target_format,
    int depth_format,
    unsigned int sample_count,
    unsigned int sample_mask,
    bool alpha_to_coverage) {
  ImGui_ImplWGPU_InitInfo info = {};
  info.Device = static_cast<WGPUDevice>(device);
  info.NumFramesInFlight = frames_in_flight;
  info.RenderTargetFormat = static_cast<WGPUTextureFormat>(render_target_format);
  info.DepthStencilFormat = static_cast<WGPUTextureFormat>(depth_format);
  info.PipelineMultisampleState.count = sample_count;
  info.PipelineMultisampleState.mask = sample_mask;
  info.PipelineMultisampleState.alphaToCoverageEnabled = alpha_to_coverage;
  return ImGui_ImplWGPU_Init(&info);
}

IMGUI_RUBY_EXPORT void imgui_ruby_wgpu_shutdown() {
  ImGui_ImplWGPU_Shutdown();
}

IMGUI_RUBY_EXPORT void imgui_ruby_wgpu_new_frame() {
  ImGui_ImplWGPU_NewFrame();
}

IMGUI_RUBY_EXPORT void imgui_ruby_wgpu_render_draw_data(
    ImDrawData* draw_data,
    void* render_pass_encoder) {
  ImGui_ImplWGPU_RenderDrawData(
      draw_data,
      static_cast<WGPURenderPassEncoder>(render_pass_encoder));
}

IMGUI_RUBY_EXPORT bool imgui_ruby_wgpu_render_draw_data_to_view(
    ImDrawData* draw_data,
    void* command_encoder,
    void* target_view) {
  WGPURenderPassColorAttachment color_attachment = {};
  color_attachment.view = static_cast<WGPUTextureView>(target_view);
  color_attachment.depthSlice = WGPU_DEPTH_SLICE_UNDEFINED;
  color_attachment.loadOp = WGPULoadOp_Load;
  color_attachment.storeOp = WGPUStoreOp_Store;

  WGPURenderPassDescriptor descriptor = {};
  descriptor.colorAttachmentCount = 1;
  descriptor.colorAttachments = &color_attachment;
  WGPURenderPassEncoder pass = wgpuCommandEncoderBeginRenderPass(
      static_cast<WGPUCommandEncoder>(command_encoder),
      &descriptor);
  if (!pass) {
    return false;
  }

  ImGui_ImplWGPU_RenderDrawData(draw_data, pass);
  wgpuRenderPassEncoderEnd(pass);
  wgpuRenderPassEncoderRelease(pass);
  return true;
}

}
