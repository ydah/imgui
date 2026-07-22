# frozen_string_literal: true

RSpec.describe ImGui::Native do
  describe ".library_candidates" do
    it "gives an explicit path precedence" do
      candidates = described_class.library_candidates("relative/libcustom.dylib")

      expect(candidates.first).to eq(File.expand_path("relative/libcustom.dylib"))
    end

    it "falls back to portable system library names" do
      expect(described_class.library_candidates).to include("cimgui_ruby", "libcimgui_ruby")
    end
  end

  it "registers the generated cimgui surface lazily" do
    expect(described_class.registered_functions).to include(:igCreateContext, :igBegin, :igButton)
    expect(described_class.registered_functions.length).to be > 1_000
  end
end
