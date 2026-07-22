# frozen_string_literal: true

RSpec.describe ImGui::IO do
  let(:context) { FFI::MemoryPointer.new(:char, 1) }
  let(:native_io) { ImGui::Native::ImGuiIO.new }

  before do
    allow(ImGui::Native).to receive(:igGetCurrentContext).and_return(context)
    allow(ImGui::Native).to receive(:igGetIO).and_return(native_io.pointer)
  end

  it "reads and writes idiomatic scalar and vector properties" do
    io = ImGui.io
    io.config_flags = ImGui::ConfigFlags::DockingEnable
    io.display_size = [1280, 720]
    io.delta_time = 1.0 / 60

    expect(io.config_flags).to eq(ImGui::ConfigFlags::DockingEnable)
    expect(io.display_size).to eq([1280.0, 720.0])
    expect(io.delta_time).to be_within(0.0001).of(1.0 / 60)
  end

  it "retains pointer-backed filenames for as long as the IO wrapper lives" do
    io = ImGui.io
    io.ini_filename = "settings/app.ini"
    GC.start

    expect(io.ini_filename).to eq("settings/app.ini")
    io.ini_filename = nil
    expect(io.ini_filename).to be_nil
  end
end
