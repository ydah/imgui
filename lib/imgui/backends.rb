# frozen_string_literal: true

module ImGui
  module Native
    attach_function :imgui_ruby_backend_load_library, %i[string string], :bool
    attach_function :imgui_ruby_backend_library_ready, [:string], :bool
    attach_function :imgui_ruby_backend_has_function, %i[string string], :bool
    attach_function :imgui_ruby_backend_required_function_count, [:string], :size_t
    attach_function :imgui_ruby_backend_required_function_name, %i[string size_t], :string
    attach_function :imgui_ruby_backend_library_error, [], :string
  end

  module Backends
    module_function

    def pointer(value)
      candidate = value.respond_to?(:handle) ? value.handle : value
      candidate = candidate.to_ptr if candidate.respond_to?(:to_ptr)
      return candidate if candidate.is_a?(FFI::Pointer)
      return FFI::Pointer.new(candidate) if candidate.is_a?(Integer)

      raise TypeError, "expected a native pointer or an object exposing #handle/#to_ptr"
    end

    def invoke(backend, function, *arguments)
      ImGui.__send__(:guard_context!)
      Native.public_send(function, *arguments)
    rescue MissingSymbolError => error
      raise BackendUnavailableError, "#{backend} backend is not included in the loaded native library: #{error.message}"
    end

    def load_runtime_library(backend, candidates)
      ImGui.__send__(:guard_context!)
      unless Native.imgui_ruby_backend_library_ready(backend)
        Array(candidates).compact.uniq.each do |path|
          break if Native.imgui_ruby_backend_load_library(backend, path.to_s)
        end
      end

      unless Native.imgui_ruby_backend_library_ready(backend)
        detail = Native.imgui_ruby_backend_library_error
        raise BackendUnavailableError,
              "unable to load the #{backend} runtime library#{detail.to_s.empty? ? "" : ": #{detail}"}"
      end

      count = Native.imgui_ruby_backend_required_function_count(backend)
      missing = count.times.filter_map do |index|
        name = Native.imgui_ruby_backend_required_function_name(backend, index)
        name unless Native.imgui_ruby_backend_has_function(backend, name)
      end
      return true if missing.empty?

      raise BackendUnavailableError,
            "#{backend} runtime library is incompatible; missing: #{missing.join(", ")}"
    rescue MissingSymbolError => error
      raise BackendUnavailableError,
            "#{backend} runtime loading is not included in the loaded native library: #{error.message}"
    end
  end
end
