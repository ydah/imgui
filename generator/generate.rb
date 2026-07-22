# frozen_string_literal: true

require "fileutils"
require "optparse"

require_relative "emitter"
require_relative "api_emitter"

root = File.expand_path("..", __dir__)
options = {
  metadata: File.join(__dir__, "vendor", "cimgui", "generator", "output"),
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
  overrides_path: options.fetch(:overrides)
).generate!

ImGuiRuby::Generator::ApiEmitter.new(
  metadata_dir: options.fetch(:metadata),
  output_path: File.join(root, "lib", "imgui", "api_generated.rb"),
  overrides_path: options.fetch(:overrides)
).generate!
