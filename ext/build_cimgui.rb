# frozen_string_literal: true

require "fileutils"
require "open3"

module ImGuiRuby
  class NativeBuilder
    def initialize(source_dir:, build_dir:, install_dir:)
      @source_dir = source_dir
      @build_dir = build_dir
      @install_dir = install_dir
    end

    def build!
      FileUtils.mkdir_p(@build_dir)
      FileUtils.mkdir_p(@install_dir)
      run("cmake", "-S", @source_dir, "-B", @build_dir, *cmake_options)
      run("cmake", "--build", @build_dir, "--config", "Release", "--parallel")
      run("cmake", "--install", @build_dir, "--config", "Release", "--prefix", @install_dir)
    end

    private

    def cmake_options
      backends = ENV.fetch("IMGUI_RUBY_BACKENDS", "").split(",").map(&:strip)
      [
        "-DCMAKE_BUILD_TYPE=Release",
        "-DIMGUI_RUBY_WITH_GLFW=#{on_off(backends.include?("glfw"))}",
        "-DIMGUI_RUBY_WITH_OPENGL3=#{on_off(backends.include?("opengl3"))}",
        "-DIMGUI_RUBY_WITH_SDL3=#{on_off(backends.include?("sdl3"))}",
        "-DIMGUI_RUBY_WITH_WGPU=#{on_off(backends.include?("wgpu"))}",
        "-DIMGUI_RUBY_WITH_IMPLOT=#{on_off(!backends.include?("no-implot"))}"
      ]
    end

    def on_off(value)
      value ? "ON" : "OFF"
    end

    def run(*command)
      output, status = Open3.capture2e(*command)
      puts output
      return if status.success?

      raise "command failed (#{status.exitstatus}): #{command.join(" ")}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  build_dir, install_dir = ARGV
  raise ArgumentError, "build and install directories are required" unless build_dir && install_dir

  ImGuiRuby::NativeBuilder.new(
    source_dir: __dir__,
    build_dir: File.expand_path(build_dir),
    install_dir: File.expand_path(install_dir)
  ).build!
end
