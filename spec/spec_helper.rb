# frozen_string_literal: true

require "imgui"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    ImGui.enforce_thread_safety!

    # Most unit specs replace native contexts with short-lived FFI pointers, so
    # they cannot exercise destroy_context's normal registry cleanup.
    %i[context_threads io_views style_views].each do |registry|
      ImGui.__send__(registry).clear
    end
  end
end
