# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rbconfig"

desc "Generate FFI declarations from cimgui metadata"
task generate: "vendor:fetch" do
  ruby File.expand_path("generator/generate.rb", __dir__)
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :vendor do
  desc "Fetch the pinned native dependencies when the cache is missing"
  task :fetch do
    ruby File.expand_path("generator/update_vendor.rb", __dir__)
  end

  desc "Verify the cached native dependency snapshots"
  task :verify do
    ruby File.expand_path("generator/update_vendor.rb", __dir__), "--verify"
  end

  desc "Update cached native dependencies from their configured branches"
  task :update do
    ruby File.expand_path("generator/update_vendor.rb", __dir__), "--latest"
  end
end

namespace :native do
  build_root = File.expand_path("tmp/native-build", __dir__)
  install_root = File.expand_path("tmp/native-install", __dir__)

  desc "Build the cached cimgui library"
  task build: "vendor:fetch" do
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


  desc "Build all supported backends and attach every generated native function"
  task :audit do
    previous_backends = ENV["IMGUI_RUBY_BACKENDS"]
    ENV["IMGUI_RUBY_BACKENDS"] = "glfw,opengl3,sdl3,wgpu"
    Rake::Task["native:build"].invoke
    library = Dir.glob(File.join(install_root, "*cimgui_ruby.{so,dylib,dll}")).first
    raise "built cimgui library was not found" unless library

    previous_library = ENV["IMGUI_RUBY_LIB"]
    ENV["IMGUI_RUBY_LIB"] = library
    ruby "-Ilib", "spec/native_symbol_audit.rb"
  ensure
    ENV["IMGUI_RUBY_BACKENDS"] = previous_backends
    ENV["IMGUI_RUBY_LIB"] = previous_library
  end

  desc "Run GLFW/OpenGL3, SDL3, and WGPU backend integration frames"
  task :integration do
    previous_backends = ENV["IMGUI_RUBY_BACKENDS"]
    ENV["IMGUI_RUBY_BACKENDS"] = "glfw,opengl3,sdl3,wgpu"
    Rake::Task["native:build"].invoke
    library = Dir.glob(File.join(install_root, "*cimgui_ruby.{so,dylib,dll}")).first
    raise "built cimgui library was not found" unless library

    require "bundler"
    Bundler.with_unbundled_env do
      sh({ "IMGUI_RUBY_LIB" => library, "IMGUI_RUBY_REQUIRE_GLFW" => "1" },
         RbConfig.ruby, "-Ilib", "spec/glfw_opengl_smoke.rb")
      sh({ "IMGUI_RUBY_LIB" => library, "IMGUI_RUBY_REQUIRE_SDL3" => "1" },
         RbConfig.ruby, "-Ilib", "spec/sdl3_smoke.rb")
      sh({ "IMGUI_RUBY_LIB" => library },
         RbConfig.ruby, "-Ilib", "spec/wgpu_smoke.rb")
    end
  ensure
    ENV["IMGUI_RUBY_BACKENDS"] = previous_backends
  end
end
