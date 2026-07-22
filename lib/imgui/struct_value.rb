# frozen_string_literal: true

module ImGui
  module StructValue
    module_function

    def vec2(value)
      values = Array(value)
      raise ArgumentError, "expected [x, y]" unless values.length == 2

      Native::ImVec2.new.tap do |vector|
        vector[:x] = Float(values[0])
        vector[:y] = Float(values[1])
      end
    end

    def vec4(value)
      values = Array(value)
      raise ArgumentError, "expected [x, y, z, w]" unless values.length == 4

      Native::ImVec4.new.tap do |vector|
        vector[:x] = Float(values[0])
        vector[:y] = Float(values[1])
        vector[:z] = Float(values[2])
        vector[:w] = Float(values[3])
      end
    end

    def to_a(vector, count)
      %i[x y z w].first(count).map { |field| vector[field] }
    end
  end
end
