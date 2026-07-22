# frozen_string_literal: true

RSpec.describe ImGui::Backends do
  it "extracts native pointers from backend objects" do
    pointer = FFI::MemoryPointer.new(:char, 1)
    window = Struct.new(:handle).new(pointer)

    expect(described_class.pointer(window)).to equal(pointer)
  end

  it "routes GLFW initialization to the generated backend symbol" do
    pointer = FFI::MemoryPointer.new(:char, 1)
    expect(described_class).to receive(:invoke)
      .with("GLFW", :ImGui_ImplGlfw_InitForOpenGL, pointer, true)
      .and_return(true)

    expect(ImGui::Backends::Glfw.init_for_opengl(pointer)).to be(true)
  end

  it "unwraps DrawData for OpenGL rendering" do
    pointer = FFI::MemoryPointer.new(:char, ImGui::Native::ImDrawData.size)
    draw_data = ImGui::DrawData.new(pointer)
    expect(described_class).to receive(:invoke)
      .with("OpenGL3", :ImGui_ImplOpenGL3_RenderDrawData, pointer)

    ImGui::Backends::OpenGL3.render_draw_data(draw_data)
  end

  it "configures WGPU through a runtime function table" do
    function = FFI::MemoryPointer.new(:char, 1)
    allow(described_class).to receive(:invoke).with("WGPU", :imgui_ruby_wgpu_required_function_count).and_return(1)
    allow(described_class).to receive(:invoke)
      .with("WGPU", :imgui_ruby_wgpu_required_function_name, 0)
      .and_return("wgpuDeviceCreateBuffer")
    allow(described_class).to receive(:invoke)
      .with("WGPU", :imgui_ruby_wgpu_set_function, "wgpuDeviceCreateBuffer", function)
      .and_return(true)
    allow(described_class).to receive(:invoke).with("WGPU", :imgui_ruby_wgpu_bridge_ready).and_return(true)
    expect(described_class).to receive(:invoke)
      .with("WGPU", :imgui_ruby_wgpu_init, kind_of(FFI::Pointer), 3, 18, 0, 1, 0xffff_ffff, false)
      .and_return(true)

    expect(
      ImGui::Backends::WGPU.init(
        device: FFI::MemoryPointer.new(:char, 1),
        render_target_format: 18,
        function_table: { "wgpuDeviceCreateBuffer" => function }
      )
    ).to be(true)
  end

  it "can create an overlay render pass from an encoder and target view" do
    draw_data = FFI::MemoryPointer.new(:char, 1)
    encoder = FFI::MemoryPointer.new(:char, 1)
    view = FFI::MemoryPointer.new(:char, 1)
    expect(described_class).to receive(:invoke)
      .with("WGPU", :imgui_ruby_wgpu_render_draw_data_to_view, draw_data, encoder, view)
      .and_return(true)

    expect(ImGui::Backends::WGPU.render_draw_data(draw_data, encoder, view)).to be(true)
  end
end

RSpec.describe ".frame" do
  it "runs backend and ImGui lifecycle operations in order" do
    calls = []
    platform = double
    renderer = double
    allow(platform).to receive(:new_frame) { calls << :platform }
    allow(renderer).to receive(:new_frame) { calls << :renderer }
    allow(renderer).to receive(:render_draw_data) { calls << :draw }
    allow(ImGui).to receive(:new_frame) { calls << :new_frame }
    allow(ImGui).to receive(:render) { calls << :render }
    allow(ImGui).to receive(:draw_data).and_return(nil)

    result = ImGui.frame(platform: platform, renderer: renderer) do
      calls << :ui
      :result
    end

    expect(result).to eq(:result)
    expect(calls).to eq(%i[renderer platform new_frame ui render draw])
  end
end
