# frozen_string_literal: true

require "fileutils"
require "rbconfig"

source_dir, ruby_arch_dir = ARGV
raise ArgumentError, "source and Ruby architecture directories are required" unless source_dir && ruby_arch_dir

library = Dir.glob(File.join(source_dir, "*cimgui_ruby.{so,dylib,dll}")).first
raise "built cimgui library was not found in #{source_dir}" unless library

host_os = RbConfig::CONFIG.fetch("host_os")
platform_os = if host_os.include?("darwin")
                "darwin"
              elsif host_os.match?(/mswin|mingw/)
                "windows"
              else
                "linux"
              end
host_cpu = RbConfig::CONFIG.fetch("host_cpu")
platform_cpu = host_cpu == "arm64" ? "aarch64" : host_cpu
destination = File.join(ruby_arch_dir, "imgui", "vendor", "#{platform_cpu}-#{platform_os}")

FileUtils.mkdir_p(destination)
FileUtils.cp(library, destination)
