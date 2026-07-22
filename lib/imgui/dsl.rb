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

    def child_id(id, size: [0, 0], child_flags: 0, window_flags: 0, &block)
      guard_context!
      opened = Native.igBeginChild_ID(
        Integer(id),
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

    def popup_context_item(id = nil, flags: PopupFlags::MouseButtonRight, &block)
      conditional_scope(
        :popup,
        :igBeginPopupContextItem,
        :igEndPopup,
        id&.to_s,
        Integer(flags),
        &block
      )
    end

    def popup_context_window(id = nil, flags: PopupFlags::MouseButtonRight, &block)
      conditional_scope(
        :popup,
        :igBeginPopupContextWindow,
        :igEndPopup,
        id&.to_s,
        Integer(flags),
        &block
      )
    end

    def popup_context_void(id = nil, flags: PopupFlags::MouseButtonRight, &block)
      conditional_scope(
        :popup,
        :igBeginPopupContextVoid,
        :igEndPopup,
        id&.to_s,
        Integer(flags),
        &block
      )
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

    def combo_preview(&block)
      conditional_scope(:combo_preview, :igBeginComboPreview, :igEndComboPreview, &block)
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

    def tooltip(&block)
      conditional_scope(:tooltip, :igBeginTooltip, :igEndTooltip, &block)
    end

    def item_tooltip(&block)
      conditional_scope(:tooltip, :igBeginItemTooltip, :igEndTooltip, &block)
    end

    def multi_select(flags: 0, selection_size: 0, items_count: -1, &block)
      pointer_scope(
        :multi_select,
        :igBeginMultiSelect,
        :igEndMultiSelect,
        Integer(flags),
        Integer(selection_size),
        Integer(items_count),
        &block
      )
    end

    def tree_node(label, &block)
      conditional_scope(:tree_node, :igTreeNode_Str, :igTreePop, label.to_s, &block)
    end

    def tree_node_ex(label, flags: 0, &block)
      conditional_scope(:tree_node, :igTreeNodeEx_Str, :igTreePop, label.to_s, Integer(flags), &block)
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

    def font(font, &block)
      push_scope(:font, :igPushFont, :igPopFont, Backends.pointer(font), &block)
    end

    def item_width(width, &block)
      push_scope(:item_width, :igPushItemWidth, :igPopItemWidth, Float(width), &block)
    end

    def text_wrap_pos(position = 0.0, &block)
      push_scope(:text_wrap_pos, :igPushTextWrapPos, :igPopTextWrapPos, Float(position), &block)
    end

    def item_flag(flag, enabled = true, &block)
      push_scope(:item_flag, :igPushItemFlag, :igPopItemFlag, Integer(flag), !!enabled, &block)
    end

    def focus_scope(id, &block)
      push_scope(:focus_scope, :igPushFocusScope, :igPopFocusScope, Integer(id), &block)
    end

    def clip_rect(minimum, maximum, intersect: false, &block)
      push_scope(
        :clip_rect,
        :igPushClipRect,
        :igPopClipRect,
        StructValue.vec2(minimum),
        StructValue.vec2(maximum),
        !!intersect,
        &block
      )
    end

    def style_color(index, color)
      arguments = [
        :style_color,
        :igPushStyleColor_Vec4,
        :igPopStyleColor,
        Integer(index),
        StructValue.vec4(color)
      ]
      return push_scope(*arguments, pop_arguments: [1]) unless block_given?

      push_scope(*arguments, pop_arguments: [1]) { yield }
    end

    def style_var(index, value)
      function, native_value = if value.is_a?(Array)
                                 [:igPushStyleVar_Vec2, StructValue.vec2(value)]
                               else
                                 [:igPushStyleVar_Float, Float(value)]
                               end
      arguments = [:style_var, function, :igPopStyleVar, Integer(index), native_value]
      return push_scope(*arguments, pop_arguments: [1]) unless block_given?

      push_scope(*arguments, pop_arguments: [1]) { yield }
    end

    def with_id(value)
      guard_context!
      push_id(value)
      return run_pushed_scope(:id, :igPopID) unless block_given?

      run_pushed_scope(:id, :igPopID) { yield }
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
      end_combo_preview: :combo_preview,
      end_list_box: :list_box,
      end_table: :table,
      end_tab_bar: :tab_bar,
      end_tab_item: :tab_item,
      end_tooltip: :tooltip,
      end_multi_select: :multi_select,
      tree_pop: :tree_node,
      end_drag_drop_source: :drag_drop_source,
      end_drag_drop_target: :drag_drop_target,
      end_group: :group,
      end_disabled: :disabled,
      pop_font: :font,
      pop_item_width: :item_width,
      pop_text_wrap_pos: :text_wrap_pos,
      pop_item_flag: :item_flag,
      pop_focus_scope: :focus_scope,
      pop_clip_rect: :clip_rect,
      pop_style_color: :style_color,
      pop_style_var: :style_var,
      pop_id: :id
    }.each do |method_name, kind|
      define_method(method_name) { close_manual_scope(kind) }
    end

    def close_scope
      scope = scope_stack.last
      raise StackError, "there is no open manual scope" unless scope

      close_manual_scope(scope.fetch(0))
    end

  end
end
