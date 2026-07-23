# frozen_string_literal: true

require "fileutils"
require "optparse"

require_relative "emitter"
require_relative "api_emitter"

root = File.expand_path("..", __dir__)
options = {
  metadata: File.join(root, "tmp", "vendor", "cimgui", "generator", "output"),
  output: File.join(root, "lib", "imgui", "native"),
  overrides: File.join(__dir__, "overrides.yml")
}

OptionParser.new do |parser|
  parser.banner = "Usage: ruby generator/generate.rb [options]"
  parser.on("--metadata DIR", "cimgui generator/output directory") { |value| options[:metadata] = value }
  parser.on("--output DIR", "generated Ruby output directory") { |value| options[:output] = value }
  parser.on("--overrides FILE", "generation overrides YAML") { |value| options[:overrides] = value }
end.parse!

ImGuiRuby::Generator::Emitter.new(
  metadata_dir: options.fetch(:metadata),
  output_dir: options.fetch(:output),
  overrides_path: options.fetch(:overrides),
  implementation_prefixes: %w[ImGui_ImplGlfw_ ImGui_ImplOpenGL3_ ImGui_ImplSDL3_]
).generate!

ImGuiRuby::Generator::ApiEmitter.new(
  metadata_dir: options.fetch(:metadata),
  output_path: File.join(root, "lib", "imgui", "api_generated.rb"),
  overrides_path: options.fetch(:overrides)
).generate!

plot_metadata = File.join(root, "tmp", "vendor", "cimplot", "generator", "output")
if File.directory?(plot_metadata)
  ImGuiRuby::Generator::Emitter.new(
    metadata_dir: plot_metadata,
    output_dir: File.join(root, "lib", "imgui", "plot", "native"),
    overrides_path: options.fetch(:overrides),
    dependency_metadata_dirs: [options.fetch(:metadata)],
    public_module: "ImPlot",
    public_enum_prefix: "ImPlot",
    predeclare_structs: true
  ).generate!
end
