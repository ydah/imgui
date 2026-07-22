# frozen_string_literal: true

module ImGui
  class << self
    def separator
      guarded_native_call(:igSeparator)
    end

    def spacing
      guarded_native_call(:igSpacing)
    end

    def new_line
      guarded_native_call(:igNewLine)
    end

    def same_line(offset: 0.0, spacing: -1.0)
      guarded_native_call(:igSameLine, Float(offset), Float(spacing))
    end

    def dummy(size)
      guarded_native_call(:igDummy, StructValue.vec2(size))
    end

    def indent(width = 0.0)
      guarded_native_call(:igIndent, Float(width))
    end

    def unindent(width = 0.0)
      guarded_native_call(:igUnindent, Float(width))
    end

    def set_next_window_pos(position, condition: 0, pivot: [0, 0])
      guarded_native_call(
        :igSetNextWindowPos,
        StructValue.vec2(position),
        Integer(condition),
        StructValue.vec2(pivot)
      )
    end

    def set_next_window_size(size, condition: 0)
      guarded_native_call(:igSetNextWindowSize, StructValue.vec2(size), Integer(condition))
    end

    def set_next_window_collapsed(collapsed, condition: 0)
      guarded_native_call(:igSetNextWindowCollapsed, !!collapsed, Integer(condition))
    end

    def set_next_window_focus
      guarded_native_call(:igSetNextWindowFocus)
    end

    def window_pos
      vector_result(:igGetWindowPos)
    end

    alias get_window_pos window_pos

    def window_size
      vector_result(:igGetWindowSize)
    end

    alias get_window_size window_size

    def content_region_available
      vector_result(:igGetContentRegionAvail)
    end

    alias get_content_region_avail content_region_available

    def cursor_pos
      vector_result(:igGetCursorPos)
    end

    alias get_cursor_pos cursor_pos

    def cursor_screen_pos
      vector_result(:igGetCursorScreenPos)
    end

    alias get_cursor_screen_pos cursor_screen_pos

    def cursor_start_pos
      vector_result(:igGetCursorStartPos)
    end

    alias get_cursor_start_pos cursor_start_pos

    def mouse_pos
      vector_result(:igGetMousePos)
    end

    alias get_mouse_pos mouse_pos

    def mouse_drag_delta(button: 0, threshold: -1.0)
      vector_result(:igGetMouseDragDelta, Integer(button), Float(threshold))
    end

    alias get_mouse_drag_delta mouse_drag_delta

    def item_rect_min
      vector_result(:igGetItemRectMin)
    end

    alias get_item_rect_min item_rect_min

    def item_rect_max
      vector_result(:igGetItemRectMax)
    end

    alias get_item_rect_max item_rect_max

    def item_rect_size
      vector_result(:igGetItemRectSize)
    end

    alias get_item_rect_size item_rect_size

    def calc_text_size(text, hide_after_double_hash: false, wrap_width: -1.0)
      vector_result(
        :igCalcTextSize,
        text.to_s,
        nil,
        !!hide_after_double_hash,
        Float(wrap_width)
      )
    end

    def set_cursor_pos(position)
      guarded_native_call(:igSetCursorPos, StructValue.vec2(position))
    end

    def set_cursor_screen_pos(position)
      guarded_native_call(:igSetCursorScreenPos, StructValue.vec2(position))
    end
  end
end
