#include <webgpu/webgpu.h>

#include <cstring>
#include <string>

#if defined(_WIN32)
#define IMGUI_RUBY_EXPORT __declspec(dllexport)
#else
#define IMGUI_RUBY_EXPORT __attribute__((visibility("default")))
#endif

#define WGPU_FUNCTIONS(X) \
  X(wgpuBindGroupLayoutRelease, WGPUProcBindGroupLayoutRelease) \
  X(wgpuBindGroupRelease, WGPUProcBindGroupRelease) \
  X(wgpuBufferDestroy, WGPUProcBufferDestroy) \
  X(wgpuBufferRelease, WGPUProcBufferRelease) \
  X(wgpuCommandEncoderBeginRenderPass, WGPUProcCommandEncoderBeginRenderPass) \
  X(wgpuDeviceCreateBindGroup, WGPUProcDeviceCreateBindGroup) \
  X(wgpuDeviceCreateBindGroupLayout, WGPUProcDeviceCreateBindGroupLayout) \
  X(wgpuDeviceCreateBuffer, WGPUProcDeviceCreateBuffer) \
  X(wgpuDeviceCreatePipelineLayout, WGPUProcDeviceCreatePipelineLayout) \
  X(wgpuDeviceCreateRenderPipeline, WGPUProcDeviceCreateRenderPipeline) \
  X(wgpuDeviceCreateSampler, WGPUProcDeviceCreateSampler) \
  X(wgpuDeviceCreateShaderModule, WGPUProcDeviceCreateShaderModule) \
  X(wgpuDeviceCreateTexture, WGPUProcDeviceCreateTexture) \
  X(wgpuDeviceGetQueue, WGPUProcDeviceGetQueue) \
  X(wgpuPipelineLayoutRelease, WGPUProcPipelineLayoutRelease) \
  X(wgpuQueueRelease, WGPUProcQueueRelease) \
  X(wgpuQueueWriteBuffer, WGPUProcQueueWriteBuffer) \
  X(wgpuQueueWriteTexture, WGPUProcQueueWriteTexture) \
  X(wgpuRenderPassEncoderDrawIndexed, WGPUProcRenderPassEncoderDrawIndexed) \
  X(wgpuRenderPassEncoderEnd, WGPUProcRenderPassEncoderEnd) \
  X(wgpuRenderPassEncoderRelease, WGPUProcRenderPassEncoderRelease) \
  X(wgpuRenderPassEncoderSetBindGroup, WGPUProcRenderPassEncoderSetBindGroup) \
  X(wgpuRenderPassEncoderSetBlendConstant, WGPUProcRenderPassEncoderSetBlendConstant) \
  X(wgpuRenderPassEncoderSetIndexBuffer, WGPUProcRenderPassEncoderSetIndexBuffer) \
  X(wgpuRenderPassEncoderSetPipeline, WGPUProcRenderPassEncoderSetPipeline) \
  X(wgpuRenderPassEncoderSetScissorRect, WGPUProcRenderPassEncoderSetScissorRect) \
  X(wgpuRenderPassEncoderSetVertexBuffer, WGPUProcRenderPassEncoderSetVertexBuffer) \
  X(wgpuRenderPassEncoderSetViewport, WGPUProcRenderPassEncoderSetViewport) \
  X(wgpuRenderPipelineRelease, WGPUProcRenderPipelineRelease) \
  X(wgpuSamplerRelease, WGPUProcSamplerRelease) \
  X(wgpuShaderModuleRelease, WGPUProcShaderModuleRelease) \
  X(wgpuTextureCreateView, WGPUProcTextureCreateView) \
  X(wgpuTextureRelease, WGPUProcTextureRelease) \
  X(wgpuTextureViewRelease, WGPUProcTextureViewRelease)

namespace {

#define DECLARE_FUNCTION(name, type) type name##_function = nullptr;
WGPU_FUNCTIONS(DECLARE_FUNCTION)
#undef DECLARE_FUNCTION

std::string bridge_error;

const char* const required_function_names[] = {
#define FUNCTION_NAME(name, type) #name,
    WGPU_FUNCTIONS(FUNCTION_NAME)
#undef FUNCTION_NAME
};

}  // namespace

extern "C" {

IMGUI_RUBY_EXPORT size_t imgui_ruby_wgpu_required_function_count() {
  return sizeof(required_function_names) / sizeof(required_function_names[0]);
}

IMGUI_RUBY_EXPORT const char* imgui_ruby_wgpu_required_function_name(size_t index) {
  if (index >= imgui_ruby_wgpu_required_function_count()) {
    return nullptr;
  }
  return required_function_names[index];
}

IMGUI_RUBY_EXPORT bool imgui_ruby_wgpu_set_function(const char* name, void* function) {
  if (!name || !function) {
    bridge_error = "WebGPU function name and address must be non-null";
    return false;
  }

#define ASSIGN_FUNCTION(function_name, type) \
  if (std::strcmp(name, #function_name) == 0) { \
    function_name##_function = reinterpret_cast<type>(function); \
    return true; \
  }
  WGPU_FUNCTIONS(ASSIGN_FUNCTION)
#undef ASSIGN_FUNCTION

  bridge_error = std::string("unexpected WebGPU function: ") + name;
  return false;
}

IMGUI_RUBY_EXPORT bool imgui_ruby_wgpu_bridge_ready() {
#define CHECK_FUNCTION(name, type) \
  if (!name##_function) { \
    bridge_error = std::string("WebGPU function is unavailable: ") + #name; \
    return false; \
  }
  WGPU_FUNCTIONS(CHECK_FUNCTION)
#undef CHECK_FUNCTION

  bridge_error.clear();
  return true;
}

IMGUI_RUBY_EXPORT const char* imgui_ruby_wgpu_bridge_error() {
  return bridge_error.c_str();
}

WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout value) {
  wgpuBindGroupLayoutRelease_function(value);
}
WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup value) {
  wgpuBindGroupRelease_function(value);
}
WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer value) {
  wgpuBufferDestroy_function(value);
}
WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer value) {
  wgpuBufferRelease_function(value);
}
WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(
    WGPUCommandEncoder encoder, const WGPURenderPassDescriptor* descriptor) {
  return wgpuCommandEncoderBeginRenderPass_function(encoder, descriptor);
}
WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(
    WGPUDevice device, const WGPUBindGroupDescriptor* descriptor) {
  return wgpuDeviceCreateBindGroup_function(device, descriptor);
}
WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(
    WGPUDevice device, const WGPUBindGroupLayoutDescriptor* descriptor) {
  return wgpuDeviceCreateBindGroupLayout_function(device, descriptor);
}
WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(
    WGPUDevice device, const WGPUBufferDescriptor* descriptor) {
  return wgpuDeviceCreateBuffer_function(device, descriptor);
}
WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(
    WGPUDevice device, const WGPUPipelineLayoutDescriptor* descriptor) {
  return wgpuDeviceCreatePipelineLayout_function(device, descriptor);
}
WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(
    WGPUDevice device, const WGPURenderPipelineDescriptor* descriptor) {
  return wgpuDeviceCreateRenderPipeline_function(device, descriptor);
}
WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(
    WGPUDevice device, const WGPUSamplerDescriptor* descriptor) {
  return wgpuDeviceCreateSampler_function(device, descriptor);
}
WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(
    WGPUDevice device, const WGPUShaderModuleDescriptor* descriptor) {
  return wgpuDeviceCreateShaderModule_function(device, descriptor);
}
WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(
    WGPUDevice device, const WGPUTextureDescriptor* descriptor) {
  return wgpuDeviceCreateTexture_function(device, descriptor);
}
WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device) {
  return wgpuDeviceGetQueue_function(device);
}
WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout value) {
  wgpuPipelineLayoutRelease_function(value);
}
WGPU_EXPORT void wgpuQueueRelease(WGPUQueue value) {
  wgpuQueueRelease_function(value);
}
WGPU_EXPORT void wgpuQueueWriteBuffer(
    WGPUQueue queue, WGPUBuffer buffer, uint64_t offset, const void* data, size_t size) {
  wgpuQueueWriteBuffer_function(queue, buffer, offset, data, size);
}
WGPU_EXPORT void wgpuQueueWriteTexture(
    WGPUQueue queue, const WGPUTexelCopyTextureInfo* destination, const void* data,
    size_t data_size, const WGPUTexelCopyBufferLayout* layout, const WGPUExtent3D* size) {
  wgpuQueueWriteTexture_function(queue, destination, data, data_size, layout, size);
}
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(
    WGPURenderPassEncoder pass, uint32_t index_count, uint32_t instance_count,
    uint32_t first_index, int32_t base_vertex, uint32_t first_instance) {
  wgpuRenderPassEncoderDrawIndexed_function(
      pass, index_count, instance_count, first_index, base_vertex, first_instance);
}
WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder pass) {
  wgpuRenderPassEncoderEnd_function(pass);
}
WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder pass) {
  wgpuRenderPassEncoderRelease_function(pass);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(
    WGPURenderPassEncoder pass, uint32_t index, WGPUBindGroup group,
    size_t offset_count, const uint32_t* offsets) {
  wgpuRenderPassEncoderSetBindGroup_function(pass, index, group, offset_count, offsets);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(
    WGPURenderPassEncoder pass, const WGPUColor* color) {
  wgpuRenderPassEncoderSetBlendConstant_function(pass, color);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(
    WGPURenderPassEncoder pass, WGPUBuffer buffer, WGPUIndexFormat format,
    uint64_t offset, uint64_t size) {
  wgpuRenderPassEncoderSetIndexBuffer_function(pass, buffer, format, offset, size);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(
    WGPURenderPassEncoder pass, WGPURenderPipeline pipeline) {
  wgpuRenderPassEncoderSetPipeline_function(pass, pipeline);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(
    WGPURenderPassEncoder pass, uint32_t x, uint32_t y, uint32_t width, uint32_t height) {
  wgpuRenderPassEncoderSetScissorRect_function(pass, x, y, width, height);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(
    WGPURenderPassEncoder pass, uint32_t slot, WGPUBuffer buffer,
    uint64_t offset, uint64_t size) {
  wgpuRenderPassEncoderSetVertexBuffer_function(pass, slot, buffer, offset, size);
}
WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(
    WGPURenderPassEncoder pass, float x, float y, float width, float height,
    float minimum_depth, float maximum_depth) {
  wgpuRenderPassEncoderSetViewport_function(
      pass, x, y, width, height, minimum_depth, maximum_depth);
}
WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline value) {
  wgpuRenderPipelineRelease_function(value);
}
WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler value) {
  wgpuSamplerRelease_function(value);
}
WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule value) {
  wgpuShaderModuleRelease_function(value);
}
WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(
    WGPUTexture texture, const WGPUTextureViewDescriptor* descriptor) {
  return wgpuTextureCreateView_function(texture, descriptor);
}
WGPU_EXPORT void wgpuTextureRelease(WGPUTexture value) {
  wgpuTextureRelease_function(value);
}
WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView value) {
  wgpuTextureViewRelease_function(value);
}

}

#undef WGPU_FUNCTIONS
