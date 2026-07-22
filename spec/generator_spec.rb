# frozen_string_literal: true

require "tmpdir"
require_relative "../generator/emitter"

RSpec.describe ImGuiRuby::Generator::Emitter do
  let(:fixture_root) { File.expand_path("fixtures/generator", __dir__) }

  it "generates deterministic lazy FFI declarations from cimgui metadata" do
    Dir.mktmpdir("imgui-generator") do |output|
      described_class.new(
        metadata_dir: File.join(fixture_root, "metadata"),
        output_dir: output,
        overrides_path: File.join(fixture_root, "overrides.yml")
      ).generate!

      generated = File.read(File.join(output, "functions.rb"))
      golden = File.read(File.join(fixture_root, "functions.rb.golden"))
      expect(generated).to eq(golden)
    end
  end

  it "maps enums, arrays, structs, and typedefs to FFI types" do
    Dir.mktmpdir("imgui-generator") do |output|
      described_class.new(
        metadata_dir: File.join(fixture_root, "metadata"),
        output_dir: output,
        overrides_path: File.join(fixture_root, "overrides.yml")
      ).generate!

      expect(File.read(File.join(output, "enums.rb"))).to include("DockingEnable = Native::ImGuiConfigFlags_DockingEnable")
      expect(File.read(File.join(output, "structs.rb"))).to include('"values[2]", [:float, 2]')
      expect(File.read(File.join(output, "typedefs.rb"))).to include("typedef :uint, :ImGuiID")
    end
  end
end
