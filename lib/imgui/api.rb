# frozen_string_literal: true

module ImGui
  class << self
    def create_context(shared_font_atlas = nil)
      context = Native.igCreateContext(shared_font_atlas)
      raise Error, "cimgui returned a null context" if null_pointer?(context)

      context_threads[context_key(context)] = Thread.current
      context
    end

    def destroy_context(context = nil)
      context ||= Native.igGetCurrentContext
      return if null_pointer?(context)

      check_context_thread!(context)
      Native.igDestroyContext(context)
      context_threads.delete(context_key(context))
      clear_context_views(context)
      nil
    end

    def current_context
      context = Native.igGetCurrentContext
      null_pointer?(context) ? nil : context
    end

    def current_context=(context)
      check_context_thread!(context) unless null_pointer?(context)
      Native.igSetCurrentContext(context)
      context
    end

    def new_frame
      guarded_native_call(:igNewFrame)
    end

    def end_frame
      guarded_native_call(:igEndFrame)
    end

    def render
      guarded_native_call(:igRender)
    end

    def draw_data
      guard_context!
      pointer = Native.igGetDrawData
      return if null_pointer?(pointer)

      DrawData.new(pointer)
    end

    def io
      context = guard_context!
      key = context_key(context)
      io_views[key] ||= IO.new(Native.igGetIO)
    end

    def style
      context = guard_context!
      key = context_key(context)
      style_views[key] ||= Style.new(Native.igGetStyle)
    end

    def ini_filename=(filename)
      io.ini_filename = filename
    end

    def unsafe_allow_threads!
      @thread_checks_enabled = false
    end

    def enforce_thread_safety!
      @thread_checks_enabled = true
    end

    def thread_checks_enabled?
      @thread_checks_enabled != false
    end

    def version_string
      Native.igGetVersion
    end

  end
end
