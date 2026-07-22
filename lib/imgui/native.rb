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
        ruby_name = signature.fetch(0)
        function_signatures[ruby_name] = signature
        registered_function_names << ruby_name unless registered_function_names.include?(ruby_name)
        define_lazy_function(ruby_name)
      end

      def load!(path: nil)
        return loaded_path if loaded?

        failures = []
        library_candidates(path).each do |candidate|
          begin
            ffi_lib candidate
            @loaded_path = candidate
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
        registered_function_names.dup.freeze
      end

      def bind_all!
        load!
        function_signatures.keys.each { |name| bind_function!(name) }
        true
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

      def function_signatures
        @function_signatures ||= {}
      end

      def registered_function_names
        @registered_function_names ||= []
      end

      def define_lazy_function(ruby_name)
        define_singleton_method(ruby_name) do |*arguments|
          load!
          bind_function!(ruby_name)
          public_send(ruby_name, *arguments)
        end
      end

      def bind_function!(ruby_name)
        signature = function_signatures.fetch(ruby_name)
        singleton_class.send(:remove_method, ruby_name)
        ffi_attach_function(*signature)
        function_signatures.delete(ruby_name)
      rescue FFI::NotFoundError => error
        define_lazy_function(ruby_name)
        raise MissingSymbolError, "#{ruby_name} is not exported by #{loaded_path}: #{error.message}"
      end

      def vendored_library_candidates
        vendor_root = File.expand_path("../../vendor", __dir__)
        platforms = ["#{FFI::Platform::ARCH}-#{FFI::Platform::OS}"]
        if FFI::Platform::ARCH == "aarch64"
          platforms << "arm64-#{FFI::Platform::OS}"
        end
        filenames = [library_filename]
        filenames << "#{LIBRARY_BASENAME}.dll" if FFI::Platform.windows?

        vendor_roots = [vendor_root]
        $LOAD_PATH.each do |load_path|
          vendor_roots << File.join(load_path, "imgui", "vendor")
        end

        vendor_roots.uniq.flat_map do |root|
          filenames.flat_map do |filename|
            platforms.map { |platform| File.join(root, platform, filename) } + [File.join(root, filename)]
          end
        end.select { |candidate| File.file?(candidate) }
      end
    end
  end
end

require_relative "native/typedefs"
require_relative "native/enums"
require_relative "native/structs"
require_relative "native/functions"
