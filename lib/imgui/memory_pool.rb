# frozen_string_literal: true

module ImGui
  module MemoryPool
    THREAD_KEY = :imgui_ruby_memory_pool

    module_function

    def pointer(type, count = 1)
      pool = Thread.current.thread_variable_get(THREAD_KEY)
      unless pool
        pool = {}
        Thread.current.thread_variable_set(THREAD_KEY, pool)
      end
      pool[[type, count]] ||= FFI::MemoryPointer.new(type, count)
    end
  end
end
