# frozen_string_literal: true

module ImGui
  class Style
    attr_reader :pointer

    def initialize(pointer)
      @pointer = pointer
      @native = Native::ImGuiStyle.new(pointer)
    end

    def alpha
      @native[:Alpha]
    end

    def alpha=(value)
      @native[:Alpha] = Float(value)
    end

    def window_padding
      StructValue.to_a(@native[:WindowPadding], 2)
    end

    def window_padding=(value)
      @native[:WindowPadding] = StructValue.vec2(value)
    end

    def color(index)
      vector = @native[:Colors][Integer(index)]
      StructValue.to_a(vector, 4)
    end

    def set_color(index, value)
      @native[:Colors][Integer(index)] = StructValue.vec4(value)
      value
    end

    def scale_all_sizes(scale)
      ImGui.__send__(:guard_context!)
      Native.ImGuiStyle_ScaleAllSizes(pointer, Float(scale))
      self
    end
  end
end
