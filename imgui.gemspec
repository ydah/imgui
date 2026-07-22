# frozen_string_literal: true

require_relative "lib/imgui/version"

Gem::Specification.new do |spec|
  spec.name = "imgui-ruby"
  spec.version = ImGui::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Ruby bindings for Dear ImGui through cimgui and FFI"
  spec.description = "Generated native bindings and an idiomatic Ruby API for Dear ImGui's docking branch."
  spec.homepage = "https://github.com/ydah/imgui"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |file|
      file == gemspec || file.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .idea/])
    end
  end
  vendored_sources = Dir.glob(
    "generator/vendor/cimgui/{cimgui.cpp,cimgui.h,cimgui_impl.cpp,cimgui_impl.h,cimconfig.h," \
    "imgui/{*.cpp,*.h,backends/*.{cpp,h},examples/libs/glfw/include/GLFW/*.h}}"
  )
  vendored_sources |= Dir.glob(
    "generator/vendor/cimplot/{cimplot.cpp,cimplot.h,implot/{implot.cpp,implot_demo.cpp,implot.h,implot_internal.h,implot_items.cpp}}"
  )
  vendored_sources |= Dir.glob("generator/vendor/sdl/include/SDL3/*.h")
  vendored_sources |= Dir.glob("generator/vendor/webgpu/{webgpu.h,LICENSE}")
  spec.files |= vendored_sources
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/extconf.rb"] if File.exist?(File.join(__dir__, "ext", "extconf.rb"))

  spec.add_dependency "ffi", ">= 1.16", "< 2"
end
