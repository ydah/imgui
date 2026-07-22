# frozen_string_literal: true

require "fileutils"
require "ffi"
require "rubygems/package"

namespace :gem do
  desc "Build a gem with the native library for the current platform"
  task :platform do
    root = File.expand_path("..", __dir__)
    ENV["IMGUI_RUBY_BACKENDS"] ||= if Gem.win_platform?
                                      "opengl3,wgpu"
                                    else
                                      "glfw,opengl3,sdl3,wgpu"
                                    end
    Rake::Task["native:build"].invoke
    install_root = File.join(root, "tmp", "native-install")
    library = Dir.glob(File.join(install_root, "*cimgui_ruby.{so,dylib,dll}")).first
    raise "built cimgui library was not found" unless library

    stage = File.join(root, "tmp", "platform-gem")
    package_dir = File.join(root, "pkg")
    FileUtils.rm_rf(stage)
    FileUtils.mkdir_p(stage)
    FileUtils.mkdir_p(package_dir)

    specification = Gem::Specification.load(File.join(root, "imgui.gemspec"))
    specification.platform = Gem::Platform.local
    specification.extensions = []
    specification.files = specification.files.reject do |file|
      file.start_with?("ext/", "generator/vendor/cimgui") || file == ".gitmodules"
    end

    platform = "#{FFI::Platform::ARCH}-#{FFI::Platform::OS}"
    native_file = File.join("vendor", platform, File.basename(library))
    specification.files << native_file

    specification.files.each do |relative_path|
      source = relative_path == native_file ? library : File.join(root, relative_path)
      destination = File.join(stage, relative_path)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(source, destination)
    end

    built_gem = Dir.chdir(stage) { Gem::Package.build(specification) }
    FileUtils.mv(File.join(stage, built_gem), File.join(package_dir, built_gem))
    puts File.join(package_dir, built_gem)
  end

  desc "Build source and current-platform gems"
  task all: ["build", "gem:platform"]
end
