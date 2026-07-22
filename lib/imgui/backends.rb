# frozen_string_literal: true

module ImGui
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
  end
end
