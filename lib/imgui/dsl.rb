# frozen_string_literal: true

module ImGui
  class << self
    def window(title, open: nil, flags: 0, &block)
      guard_context!
      open_pointer = boolean_pointer(open)
      run_scope(
        :window,
        :igEnd,
        Native.igBegin(title.to_s, open_pointer, Integer(flags)),
        always_close: true,
        &block
      )
    end

    def child(id, size: [0, 0], child_flags: 0, window_flags: 0, &block)
      guard_context!
      opened = Native.igBeginChild_Str(
        id.to_s,
        StructValue.vec2(size),
        Integer(child_flags),
        Integer(window_flags)
      )
      run_scope(:child, :igEndChild, opened, always_close: true, &block)
    end

    def menu_bar(&block)
      conditional_scope(:menu_bar, :igBeginMenuBar, :igEndMenuBar, &block)
    end

    def main_menu_bar(&block)
      conditional_scope(:main_menu_bar, :igBeginMainMenuBar, :igEndMainMenuBar, &block)
    end

    def menu(label, enabled: true, &block)
      conditional_scope(:menu, :igBeginMenu, :igEndMenu, label.to_s, !!enabled, &block)
    end

    def popup(id, flags: 0, &block)
      conditional_scope(:popup, :igBeginPopup, :igEndPopup, id.to_s, Integer(flags), &block)
    end

    def popup_modal(title, open: nil, flags: 0, &block)
      conditional_scope(
        :popup,
        :igBeginPopupModal,
        :igEndPopup,
        title.to_s,
        boolean_pointer(open),
        Integer(flags),
        &block
      )
    end

    def combo(label, preview = nil, flags: 0, &block)
      conditional_scope(:combo, :igBeginCombo, :igEndCombo, label.to_s, preview, Integer(flags), &block)
    end

    def list_box(label, size: [0, 0], &block)
      conditional_scope(
        :list_box,
        :igBeginListBox,
        :igEndListBox,
        label.to_s,
        StructValue.vec2(size),
        &block
      )
    end

    def table(id, columns, flags: 0, outer_size: [0, 0], inner_width: 0.0, &block)
      conditional_scope(
        :table,
        :igBeginTable,
        :igEndTable,
        id.to_s,
        Integer(columns),
        Integer(flags),
        StructValue.vec2(outer_size),
        Float(inner_width),
        &block
      )
    end

    def tab_bar(id, flags: 0, &block)
      conditional_scope(:tab_bar, :igBeginTabBar, :igEndTabBar, id.to_s, Integer(flags), &block)
    end

    def tab_item(label, open: nil, flags: 0, &block)
      conditional_scope(
        :tab_item,
        :igBeginTabItem,
        :igEndTabItem,
        label.to_s,
        boolean_pointer(open),
        Integer(flags),
        &block
      )
    end

    def tree_node(label, &block)
      conditional_scope(:tree_node, :igTreeNode_Str, :igTreePop, label.to_s, &block)
    end

    def drag_drop_source(flags: 0, &block)
      conditional_scope(
        :drag_drop_source,
        :igBeginDragDropSource,
        :igEndDragDropSource,
        Integer(flags),
        &block
      )
    end

    def drag_drop_target(&block)
      conditional_scope(:drag_drop_target, :igBeginDragDropTarget, :igEndDragDropTarget, &block)
    end

    def group(&block)
      void_scope(:group, :igBeginGroup, :igEndGroup, &block)
    end

    def disabled(disabled = true, &block)
      void_scope(:disabled, :igBeginDisabled, :igEndDisabled, !!disabled, &block)
    end

    def style_color(index, color)
      guard_context!
      Native.igPushStyleColor_Vec4(Integer(index), StructValue.vec4(color))
      pushed = true
      return true unless block_given?

      yield
    ensure
      Native.igPopStyleColor(1) if pushed && block_given?
    end

    def style_var(index, value)
      guard_context!
      if value.is_a?(Array)
        Native.igPushStyleVar_Vec2(Integer(index), StructValue.vec2(value))
      else
        Native.igPushStyleVar_Float(Integer(index), Float(value))
      end
      pushed = true
      return true unless block_given?

      yield
    ensure
      Native.igPopStyleVar(1) if pushed && block_given?
    end

    def with_id(value)
      guard_context!
      push_id(value)
      pushed = true
      return true unless block_given?

      yield
    ensure
      Native.igPopID if pushed && block_given?
    end

    def end_window
      close_manual_scope(:window)
    end

    def end_child
      close_manual_scope(:child)
    end

    {
      end_menu_bar: :menu_bar,
      end_main_menu_bar: :main_menu_bar,
      end_menu: :menu,
      end_popup: :popup,
      end_combo: :combo,
      end_list_box: :list_box,
      end_table: :table,
      end_tab_bar: :tab_bar,
      end_tab_item: :tab_item,
      tree_pop: :tree_node,
      end_drag_drop_source: :drag_drop_source,
      end_drag_drop_target: :drag_drop_target,
      end_group: :group,
      end_disabled: :disabled
    }.each do |method_name, kind|
      define_method(method_name) { close_manual_scope(kind) }
    end

    def close_scope
      scope = scope_stack.last
      raise StackError, "there is no open manual scope" unless scope

      close_manual_scope(scope.fetch(0))
    end

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
