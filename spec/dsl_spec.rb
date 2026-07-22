# frozen_string_literal: true

RSpec.describe "ImGui block DSL" do
  let(:context) { FFI::MemoryPointer.new(:char, 1) }

  before do
    allow(ImGui::Native).to receive(:igGetCurrentContext).and_return(context)
  end

  it "always ends a collapsed window without running its block" do
    allow(ImGui::Native).to receive(:igBegin).and_return(false)
    expect(ImGui::Native).to receive(:igEnd)
    ran = false

    result = ImGui.window("Stats") { ran = true }

    expect(result).to be(false)
    expect(ran).to be(false)
  end

  it "ends a window when the block raises" do
    allow(ImGui::Native).to receive(:igBegin).and_return(true)
    expect(ImGui::Native).to receive(:igEnd)

    expect do
      ImGui.window("Stats") { raise "failure" }
    end.to raise_error("failure")
  end

  it "only ends conditional scopes that opened" do
    allow(ImGui::Native).to receive(:igBeginMenu).and_return(false)
    expect(ImGui::Native).not_to receive(:igEndMenu)

    expect(ImGui.menu("File") { raise "must not run" }).to be(false)
  end

  it "supports explicit close methods for blockless calls" do
    allow(ImGui::Native).to receive(:igBegin).and_return(false)
    expect(ImGui::Native).to receive(:igEnd)

    expect(ImGui.window("Manual")).to be(false)
    ImGui.end_window
  end

  it "detects mismatched manual scope closes" do
    allow(ImGui::Native).to receive(:igBegin).and_return(true)
    ImGui.window("Manual")

    expect { ImGui.end_child }.to raise_error(ImGui::StackError, /expected child scope/)
    expect(ImGui::Native).to receive(:igEnd)
    ImGui.end_window
  end

  it "balances style and ID stacks when blocks raise" do
    allow(ImGui::Native).to receive(:igPushStyleColor_Vec4)
    allow(ImGui::Native).to receive(:igPushID_Str)
    expect(ImGui::Native).to receive(:igPopStyleColor).with(1)
    expect(ImGui::Native).to receive(:igPopID)

    expect do
      ImGui.style_color(ImGui::Col::Text, [1, 0, 0, 1]) do
        ImGui.with_id("row") { raise "failure" }
      end
    end.to raise_error("failure")
  end
end
