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

  it "reports the deferred WGPU bridge clearly" do
    expect { ImGui::Backends::WGPU.init(device: 1) }
      .to raise_error(ImGui::BackendUnavailableError, /stagecraft/)
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
