# frozen_string_literal: true

module ImGui
  class << self
    def text(value, *format_arguments)
      string = format_arguments.empty? ? value.to_s : format(value.to_s, *format_arguments)
      guarded_native_call(:igTextUnformatted, string, nil)
    end

    def text_wrapped(value, *format_arguments)
      guard_context!
      Native.igPushTextWrapPos(0.0)
      wrapped = true
      text(value, *format_arguments)
    ensure
      Native.igPopTextWrapPos if wrapped
    end

    def text_disabled(value, *format_arguments)
      text_colored(style.color(Col::TextDisabled), value, *format_arguments)
    end

    def bullet_text(value, *format_arguments)
      guard_context!
      Native.igBullet
      text(value, *format_arguments)
    end

    def label_text(label, value, *format_arguments)
      string = format_arguments.empty? ? value.to_s : format(value.to_s, *format_arguments)
      text("#{label}: #{string}")
    end

    def set_tooltip(value, *format_arguments)
      guard_context!
      opened = Native.igBeginTooltip
      return false unless opened

      text(value, *format_arguments)
    ensure
      Native.igEndTooltip if opened
    end

    def text_colored(color, value, *format_arguments)
      string = format_arguments.empty? ? value.to_s : format(value.to_s, *format_arguments)
      guard_context!
      Native.igPushStyleColor_Vec4(Col::Text, StructValue.vec4(color))
      pushed = true
      Native.igTextUnformatted(string, nil)
    ensure
      Native.igPopStyleColor(1) if pushed
    end

    def button(label, size: [0, 0])
      guarded_native_call(:igButton, label.to_s, StructValue.vec2(size))
    end

    def small_button(label)
      guarded_native_call(:igSmallButton, label.to_s)
    end

    def invisible_button(id, size, flags: 0)
      guarded_native_call(:igInvisibleButton, id.to_s, StructValue.vec2(size), Integer(flags))
    end

    def checkbox(label, value)
      edit_scalar(:igCheckbox, label.to_s, value, type: :bool, arguments: [])
    end

    def radio_button(label, active)
      guarded_native_call(:igRadioButton_Bool, label.to_s, !!active)
    end

    def slider_float(label, value, minimum, maximum, format: "%.3f", flags: 0)
      edit_scalar(
        :igSliderFloat,
        label.to_s,
        value,
        type: :float,
        arguments: [Float(minimum), Float(maximum), format, Integer(flags)]
      )
    end

    def slider_int(label, value, minimum, maximum, format: "%d", flags: 0)
      edit_scalar(
        :igSliderInt,
        label.to_s,
        value,
        type: :int,
        arguments: [Integer(minimum), Integer(maximum), format, Integer(flags)]
      )
    end

    (2..4).each do |count|
      define_method("slider_float#{count}") do |label, value, minimum, maximum, format: "%.3f", flags: 0|
        edit_vector(
          "igSliderFloat#{count}".to_sym,
          label.to_s,
          value,
          count: count,
          arguments: [Float(minimum), Float(maximum), format, Integer(flags)]
        )
      end
    end

    def drag_float(label, value, speed: 1.0, minimum: 0.0, maximum: 0.0, format: "%.3f", flags: 0)
      edit_scalar(
        :igDragFloat,
        label.to_s,
        value,
        type: :float,
        arguments: [Float(speed), Float(minimum), Float(maximum), format, Integer(flags)]
      )
    end

    def drag_int(label, value, speed: 1.0, minimum: 0, maximum: 0, format: "%d", flags: 0)
      edit_scalar(
        :igDragInt,
        label.to_s,
        value,
        type: :int,
        arguments: [Float(speed), Integer(minimum), Integer(maximum), format, Integer(flags)]
      )
    end

    def input_float(label, value, step: 0.0, fast_step: 0.0, format: "%.3f", flags: 0)
      edit_scalar(
        :igInputFloat,
        label.to_s,
        value,
        type: :float,
        arguments: [Float(step), Float(fast_step), format, Integer(flags)]
      )
    end

    def input_int(label, value, step: 1, fast_step: 100, flags: 0)
      edit_scalar(
        :igInputInt,
        label.to_s,
        value,
        type: :int,
        arguments: [Integer(step), Integer(fast_step), Integer(flags)]
      )
    end

    def color_edit3(label, value, flags: 0)
      edit_vector(:igColorEdit3, label.to_s, value, count: 3, arguments: [Integer(flags)])
    end

    def color_edit4(label, value, flags: 0)
      edit_vector(:igColorEdit4, label.to_s, value, count: 4, arguments: [Integer(flags)])
    end

    def input_text(label, value, capacity: nil, flags: 0, callback: nil, user_data: nil)
      guard_context!
      state = value.is_a?(Value) ? value : Value.text(value, capacity: capacity)
      require_value_type!(state, :text)
      changed = Native.igInputText(
        label.to_s,
        state.pointer,
        state.capacity,
        Integer(flags),
        callback,
        user_data
      )
      value.is_a?(Value) ? changed : [changed, state.get]
    end

    def selectable(label, selected = false, flags: 0, size: [0, 0])
      guarded_native_call(
        :igSelectable_Bool,
        label.to_s,
        !!selected,
        Integer(flags),
        StructValue.vec2(size)
      )
    end

    def menu_item(label, shortcut: nil, selected: false, enabled: true)
      guarded_native_call(:igMenuItem_Bool, label.to_s, shortcut, !!selected, !!enabled)
    end

    def progress_bar(fraction, size: [-Float::MIN, 0], overlay: nil)
      guarded_native_call(:igProgressBar, Float(fraction), StructValue.vec2(size), overlay)
    end
  end
end
