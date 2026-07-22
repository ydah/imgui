# frozen_string_literal: true

RSpec.describe ImGui do
  it "exposes the gem version" do
    expect(ImGui::VERSION).to eq("0.1.0")
  end

  it "loads generated enums and structs without loading the shared library" do
    expect(ImGui::ConfigFlags::DockingEnable).to eq(1 << 7)
    expect(ImGui::Native::ImVec2.size).to eq(FFI.type_size(:float) * 2)
    expect(ImGui::Native).not_to be_loaded
  end
end
