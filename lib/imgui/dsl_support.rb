# frozen_string_literal: true

module ImGui
  class << self
    private

    def conditional_scope(kind, begin_function, end_function, *arguments, &block)
      guard_context!
      opened = Native.public_send(begin_function, *arguments)
      run_scope(kind, end_function, opened, always_close: false, &block)
    end

    def void_scope(kind, begin_function, end_function, *arguments, &block)
      guard_context!
      Native.public_send(begin_function, *arguments)
      run_scope(kind, end_function, true, always_close: true, &block)
    end

    def run_scope(kind, end_function, opened, always_close:, &block)
      should_close = always_close || opened
      unless block
        scope_stack << [kind, end_function] if should_close
        return opened
      end

      return false unless should_close

      begin
        opened ? block.call : false
      ensure
        Native.public_send(end_function)
      end
    end

    def close_manual_scope(expected_kind)
      guard_context!
      scope = scope_stack.pop
      unless scope&.fetch(0) == expected_kind
        scope_stack << scope if scope
        actual = scope&.fetch(0) || "none"
        raise StackError, "expected #{expected_kind} scope, found #{actual}"
      end

      Native.public_send(scope.fetch(1))
    end

    def scope_stack
      Thread.current.thread_variable_get(:imgui_ruby_scope_stack) || begin
        stack = []
        Thread.current.thread_variable_set(:imgui_ruby_scope_stack, stack)
        stack
      end
    end

    def boolean_pointer(value)
      return nil if value.nil?
      if value.is_a?(Value)
        require_value_type!(value, :bool)
        return value.pointer
      end

      pointer = MemoryPool.pointer(:bool)
      pointer.put(:bool, 0, !!value)
      pointer
    end

    def push_id(value)
      case value
      when String then Native.igPushID_Str(value)
      when Integer then Native.igPushID_Int(value)
      when FFI::Pointer then Native.igPushID_Ptr(value)
      else Native.igPushID_Ptr(FFI::Pointer.new(value.object_id))
      end
    end
  end
end
