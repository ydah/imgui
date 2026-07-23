# frozen_string_literal: true

require "fileutils"
require "rubygems/package"

module ImGuiRuby
  class SourceGemBuilder
    def initialize(root:)
      @root = root
      @cache_root = File.join(root, "tmp", "vendor")
      @stage = File.join(root, "tmp", "source-gem")
      @package_dir = File.join(root, "pkg")
    end

    def build!
      specification = Gem::Specification.load(File.join(@root, "imgui.gemspec")).dup
      project_files = specification.files
      native_files = native_source_files
      specification.files = (project_files + native_files.keys).sort

      prepare_stage!
      copy_project_files!(project_files)
      copy_native_files!(native_files)
      package = Dir.chdir(@stage) { Gem::Package.build(specification) }
      destination = File.join(@package_dir, package)
      FileUtils.rm_f(destination)
      FileUtils.mv(File.join(@stage, package), destination)
      puts "#{specification.full_name} built to #{relative(destination)}."
    end

    private

    def native_source_files
      Dir.glob(File.join(@cache_root, "**", "*"))
         .select { |path| File.file?(path) }
         .reject { |path| path.include?("/generator/output/") }
         .to_h do |path|
           relative_path = path.delete_prefix("#{@cache_root}/")
           [File.join("vendor-src", relative_path), path]
         end
    end

    def prepare_stage!
      FileUtils.rm_rf(@stage)
      FileUtils.mkdir_p(@stage)
      FileUtils.mkdir_p(@package_dir)
    end

    def copy_project_files!(files)
      files.each do |relative_path|
        source = File.join(@root, relative_path)
        copy!(source, File.join(@stage, relative_path))
      end
    end

    def copy_native_files!(files)
      files.each { |relative_path, source| copy!(source, File.join(@stage, relative_path)) }
    end

    def copy!(source, destination)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(source, destination)
    end

    def relative(path)
      path.delete_prefix("#{@root}/")
    end
  end
end

Rake::Task["build"].clear
desc "Build the source gem with pinned native sources"
task build: "vendor:fetch" do
  ImGuiRuby::SourceGemBuilder.new(root: File.expand_path("..", __dir__)).build!
end
