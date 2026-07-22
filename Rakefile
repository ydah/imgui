# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Generate FFI declarations from cimgui metadata"
task :generate do
  ruby File.expand_path("generator/generate.rb", __dir__)
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
