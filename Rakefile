# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Generate FFI declarations from cimgui metadata"
task :generate do
  ruby File.expand_path("generator/generate.rb", __dir__)
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :native do
  build_root = File.expand_path("tmp/native-build", __dir__)
  install_root = File.expand_path("tmp/native-install", __dir__)

  desc "Build the bundled cimgui library"
  task :build do
    require_relative "ext/build_cimgui"

    ImGuiRuby::NativeBuilder.new(
      source_dir: File.expand_path("ext", __dir__),
      build_dir: build_root,
      install_dir: install_root
    ).build!
  end

  desc "Build cimgui and run a real headless ImGui frame"
  task spec: :build do
    library = Dir.glob(File.join(install_root, "*cimgui_ruby.{so,dylib,dll}")).first
    raise "built cimgui library was not found" unless library

    previous_library = ENV["IMGUI_RUBY_LIB"]
    ENV["IMGUI_RUBY_LIB"] = library
    ruby "-Ilib", "spec/native_smoke.rb"
  ensure
    ENV["IMGUI_RUBY_LIB"] = previous_library
  end
end
