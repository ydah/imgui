# frozen_string_literal: true

RSpec.describe "ImGui layer 2 API" do
  let(:context) { FFI::MemoryPointer.new(:char, 1) }

  before do
    allow(ImGui::Native).to receive(:igGetCurrentContext).and_return(context)
  end

  after do
    ImGui.enforce_thread_safety!
  end

  it "returns changed and the updated scalar for immediate values" do
    allow(ImGui::Native).to receive(:igSliderFloat) do |_label, pointer, *_arguments|
      pointer.write_float(2.5)
      true
    end

    expect(ImGui.slider_float("Speed", 1.0, 0.0, 10.0)).to eq([true, 2.5])
  end

  it "updates Value objects in place and returns only the changed flag" do
    value = ImGui::Value.bool(false)
    allow(ImGui::Native).to receive(:igCheckbox) do |_label, pointer|
      pointer.put(:bool, 0, true)
      true
    end

    expect(ImGui.checkbox("Enabled", value)).to be(true)
    expect(value.get).to be(true)
  end

  it "passes formatted text through the non-varargs native function" do
    expect(ImGui::Native).to receive(:igTextUnformatted).with("100% ready", nil)

    ImGui.text("%d%% ready", 100)
  end

  it "applies generated cimgui defaults through snake_case methods" do
    expect(ImGui::Native).to receive(:igIsItemHovered).with(0).and_return(true)

    expect(ImGui.is_item_hovered).to be(true)
  end

  it "turns native vector return parameters into Ruby arrays" do
    allow(ImGui::Native).to receive(:igGetWindowPos) do |pointer|
      pointer.write_array_of_float([12.0, 34.0])
    end

    expect(ImGui.window_pos).to eq([12.0, 34.0])
    expect(ImGui.get_window_pos).to eq([12.0, 34.0])
  end

  it "raises before a UI call when no context exists" do
    allow(ImGui::Native).to receive(:igGetCurrentContext).and_return(FFI::Pointer::NULL)

    expect { ImGui.button("OK") }.to raise_error(ImGui::NoContextError)
  end

  it "enforces context thread affinity" do
    allow(ImGui::Native).to receive(:igCreateContext).and_return(context)
    ImGui.create_context

    error = Thread.new do
      ImGui.button("wrong thread")
    rescue StandardError => caught
      caught
    end.value

    expect(error).to be_a(ImGui::ThreadError)
  end

  it "allows thread checks to be disabled explicitly" do
    ImGui.unsafe_allow_threads!
    allow(ImGui::Native).to receive(:igButton).and_return(true)

    expect(Thread.new { ImGui.button("worker") }.value).to be(true)
  end
end
