# frozen_string_literal: true

require "imgui/plot"

RSpec.describe ImPlot do
  let(:imgui_context) { FFI::MemoryPointer.new(:char, 1) }
  let(:plot_context) { FFI::MemoryPointer.new(:char, 1) }

  before do
    allow(ImGui::Native).to receive(:igGetCurrentContext).and_return(imgui_context)
    allow(ImGui::Native).to receive(:ImPlot_GetCurrentContext).and_return(plot_context)
  end

  it "generates the complete cimplot native surface" do
    expect(ImGui::Native.registered_functions).to include(
      :ImPlot_BeginPlot,
      :ImPlot_PlotLine_doublePtrdoublePtr,
      :ImPlot_EndPlot
    )
    expect(ImGui::Native.registered_functions.grep(/\AImPlot_/).length).to be > 500
  end

  it "balances plot scopes when a block raises" do
    allow(ImGui::Native).to receive(:ImPlot_BeginPlot).and_return(true)
    expect(ImGui::Native).to receive(:ImPlot_EndPlot)

    expect { described_class.plot("Metrics") { raise "failure" } }.to raise_error("failure")
  end

  it "passes Ruby arrays to the double precision plotting overload" do
    expect(ImGui::Native).to receive(:ImPlot_PlotLine_doublePtrdoublePtr) do |label, xs, ys, count, flags, offset, stride|
      expect(label).to eq("series")
      expect(xs.read_array_of_double(count)).to eq([1.0, 2.0])
      expect(ys.read_array_of_double(count)).to eq([3.0, 4.0])
      expect([flags, offset, stride]).to eq([0, 0, 8])
    end

    described_class.plot_line("series", [3, 4], xs: [1, 2])
  end

  it "rejects mismatched series lengths before calling native code" do
    expect do
      described_class.plot_scatter("series", [1, 2], xs: [1])
    end.to raise_error(ArgumentError, /expected 2 values/)
  end
end
