# frozen_string_literal: true

require "ffi"

module ImGui
  module Native
    extend FFI::Library

    LIBRARY_BASENAME = "cimgui_ruby"

    class << self
      alias ffi_attach_function attach_function

      attr_reader :loaded_path

      def attach_function(*signature)
        return ffi_attach_function(*signature) if loaded?

        pending_functions << signature
        ruby_name = signature.fetch(0)
        define_singleton_method(ruby_name) do |*arguments|
          load!
          public_send(ruby_name, *arguments)
        end
      end

      def load!(path: nil)
        return loaded_path if loaded?

        failures = []
        library_candidates(path).each do |candidate|
          begin
            ffi_lib candidate
            @loaded_path = candidate
            bind_pending_functions!
            return loaded_path
          rescue LoadError, FFI::NotFoundError => error
            failures << "#{candidate}: #{error.message.lines.first&.strip}"
          end
        end

        message = <<~MESSAGE
          Unable to load #{library_filename}.
          Set IMGUI_RUBY_LIB to the compiled library, install the platform-specific
          imgui-ruby gem, or build the source gem with CMake and a C++17 compiler.
          Tried:
          #{failures.map { |failure| "  - #{failure}" }.join("\n")}
        MESSAGE
        raise LibraryLoadError, message
      end

      def loaded?
        !@loaded_path.nil?
      end

      def registered_functions
        pending_functions.map(&:first).freeze
      end

      def library_candidates(explicit_path = nil)
        requested = explicit_path || ENV["IMGUI_RUBY_LIB"]
        candidates = []
        candidates << File.expand_path(requested) if requested && !requested.empty?

        candidates.concat(vendored_library_candidates)
        candidates.concat([LIBRARY_BASENAME, "lib#{LIBRARY_BASENAME}"])
        candidates.uniq
      end

      def library_filename
        "lib#{LIBRARY_BASENAME}.#{FFI::Platform::LIBSUFFIX}"
      end

      private

      def pending_functions
        @pending_functions ||= []
      end

      def bind_pending_functions!
        functions = pending_functions.dup
        pending_functions.clear

        functions.each do |signature|
          singleton_class.send(:remove_method, signature.fetch(0))
          ffi_attach_function(*signature)
        end
      rescue StandardError
        @loaded_path = nil
        pending_functions.concat(functions)
        raise
      end

      def vendored_library_candidates
        vendor_root = File.expand_path("../../vendor", __dir__)
        platform = "#{FFI::Platform::ARCH}-#{FFI::Platform::OS}"
        filenames = [library_filename]
        filenames << "#{LIBRARY_BASENAME}.dll" if FFI::Platform.windows?

        filenames.flat_map do |filename|
          [
            File.join(vendor_root, platform, filename),
            File.join(vendor_root, filename)
          ]
        end.select { |candidate| File.file?(candidate) }
      end
    end
  end
end

require_relative "native/typedefs"
require_relative "native/enums"
require_relative "native/structs"
require_relative "native/functions"
