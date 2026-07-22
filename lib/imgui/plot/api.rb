# frozen_string_literal: true

module ImPlot
  class Error < ImGui::Error; end
  class NoContextError < Error; end

  class << self
    def create_context
      ImGui.__send__(:guard_context!)
      context = ImGui::Native.ImPlot_CreateContext
      raise Error, "cimplot returned a null context" if null_pointer?(context)

      context
    end

    def destroy_context(context = nil)
      context ||= current_context
      return if context.nil?

      ImGui.__send__(:guard_context!)
      ImGui::Native.ImPlot_DestroyContext(context)
      nil
    end

    def current_context
      context = ImGui::Native.ImPlot_GetCurrentContext
      null_pointer?(context) ? nil : context
    end

    def current_context=(context)
      ImGui.__send__(:guard_context!)
      ImGui::Native.ImPlot_SetCurrentContext(context)
      context
    end

    def plot(title, size: [-1, 0], flags: 0, &block)
      plot_guard!
      opened = ImGui::Native.ImPlot_BeginPlot(title.to_s, ImGui::StructValue.vec2(size), Integer(flags))
      plot_scope(:plot, :ImPlot_EndPlot, opened, &block)
    end

    def subplots(title, rows:, columns:, size: [-1, 0], flags: 0, row_ratios: nil, column_ratios: nil, &block)
      plot_guard!
      row_pointer = optional_float_array(row_ratios, rows)
      column_pointer = optional_float_array(column_ratios, columns)
      opened = ImGui::Native.ImPlot_BeginSubplots(
        title.to_s,
        Integer(rows),
        Integer(columns),
        ImGui::StructValue.vec2(size),
        Integer(flags),
        row_pointer,
        column_pointer
      )
      plot_scope(:subplots, :ImPlot_EndSubplots, opened, &block)
    end

    def setup_axes(x_label = nil, y_label = nil, x_flags: 0, y_flags: 0)
      plot_guard!
      ImGui::Native.ImPlot_SetupAxes(x_label&.to_s, y_label&.to_s, Integer(x_flags), Integer(y_flags))
    end

    def setup_axis(axis, label = nil, flags: 0)
      plot_guard!
      ImGui::Native.ImPlot_SetupAxis(Integer(axis), label&.to_s, Integer(flags))
    end

    def setup_axis_limits(axis, minimum, maximum, condition: 0)
      plot_guard!
      ImGui::Native.ImPlot_SetupAxisLimits(Integer(axis), Float(minimum), Float(maximum), Integer(condition))
    end

    def setup_axes_limits(x_minimum, x_maximum, y_minimum, y_maximum, condition: 0)
      plot_guard!
      ImGui::Native.ImPlot_SetupAxesLimits(
        Float(x_minimum),
        Float(x_maximum),
        Float(y_minimum),
        Float(y_maximum),
        Integer(condition)
      )
    end

    def plot_line(label, values, xs: nil, x_scale: 1.0, x_start: 0.0, flags: 0, offset: 0)
      plot_series(:ImPlot_PlotLine, label, values, xs, x_scale, x_start, flags, offset)
    end

    def plot_scatter(label, values, xs: nil, x_scale: 1.0, x_start: 0.0, flags: 0, offset: 0)
      plot_series(:ImPlot_PlotScatter, label, values, xs, x_scale, x_start, flags, offset)
    end

    def plot_stairs(label, values, xs: nil, x_scale: 1.0, x_start: 0.0, flags: 0, offset: 0)
      plot_series(:ImPlot_PlotStairs, label, values, xs, x_scale, x_start, flags, offset)
    end

    def plot_bars(label, values, xs: nil, bar_size: 0.67, shift: 0.0, flags: 0, offset: 0)
      plot_guard!
      ys = double_array(values)
      stride = FFI.type_size(:double)
      if xs
        x_values = double_array(xs, expected: values.length)
        return ImGui::Native.ImPlot_PlotBars_doublePtrdoublePtr(
          label.to_s, x_values, ys, values.length, Float(bar_size), Integer(flags), Integer(offset), stride
        )
      end

      ImGui::Native.ImPlot_PlotBars_doublePtrInt(
        label.to_s, ys, values.length, Float(bar_size), Float(shift), Integer(flags), Integer(offset), stride
      )
    end

    def plot_histogram(label, values, bins: Bin::Sturges, bar_scale: 1.0, range: nil, flags: 0)
      plot_guard!
      data = double_array(values)
      native_range = plot_range(range)
      ImGui::Native.ImPlot_PlotHistogram_doublePtr(
        label.to_s,
        data,
        values.length,
        Integer(bins),
        Float(bar_scale),
        native_range,
        Integer(flags)
      )
    end

    def style_color(index, color)
      plot_guard!
      ImGui::Native.ImPlot_PushStyleColor_Vec4(Integer(index), ImGui::StructValue.vec4(color))
      pushed = true
      return manual_plot_push(:style_color, :ImPlot_PopStyleColor, [1]) unless block_given?

      yield
    ensure
      ImGui::Native.ImPlot_PopStyleColor(1) if pushed && block_given?
    end

    def style_var(index, value)
      plot_guard!
      if value.is_a?(Array)
        ImGui::Native.ImPlot_PushStyleVar_Vec2(Integer(index), ImGui::StructValue.vec2(value))
      else
        ImGui::Native.ImPlot_PushStyleVar_Float(Integer(index), Float(value))
      end
      pushed = true
      return manual_plot_push(:style_var, :ImPlot_PopStyleVar, [1]) unless block_given?

      yield
    ensure
      ImGui::Native.ImPlot_PopStyleVar(1) if pushed && block_given?
    end

    def end_plot
      close_plot_scope(:plot)
    end

    def end_subplots
      close_plot_scope(:subplots)
    end

    def pop_style_color
      close_plot_scope(:style_color)
    end

    def pop_style_var
      close_plot_scope(:style_var)
    end

    private

    def plot_series(prefix, label, values, xs, x_scale, x_start, flags, offset)
      plot_guard!
      ys = double_array(values)
      stride = FFI.type_size(:double)
      if xs
        x_values = double_array(xs, expected: values.length)
        function = "#{prefix}_doublePtrdoublePtr".to_sym
        return ImGui::Native.public_send(
          function, label.to_s, x_values, ys, values.length, Integer(flags), Integer(offset), stride
        )
      end

      function = "#{prefix}_doublePtrInt".to_sym
      ImGui::Native.public_send(
        function,
        label.to_s,
        ys,
        values.length,
        Float(x_scale),
        Float(x_start),
        Integer(flags),
        Integer(offset),
        stride
      )
    end

    def plot_scope(kind, end_function, opened)
      unless block_given?
        plot_scope_stack << [kind, end_function, []] if opened
        return opened
      end
      return false unless opened

      begin
        yield
      ensure
        ImGui::Native.public_send(end_function)
      end
    end

    def manual_plot_push(kind, pop_function, arguments)
      plot_scope_stack << [kind, pop_function, arguments]
      true
    end

    def close_plot_scope(expected)
      plot_guard!
      scope = plot_scope_stack.pop
      unless scope&.first == expected
        plot_scope_stack << scope if scope
        raise ImGui::StackError, "expected #{expected} scope, found #{scope&.first || "none"}"
      end

      ImGui::Native.public_send(scope.fetch(1), *scope.fetch(2))
    end

    def plot_scope_stack
      Thread.current.thread_variable_get(:imgui_ruby_plot_scope_stack) || begin
        stack = []
        Thread.current.thread_variable_set(:imgui_ruby_plot_scope_stack, stack)
        stack
      end
    end

    def plot_guard!
      ImGui.__send__(:guard_context!)
      raise NoContextError, "create an ImPlot context before plotting" unless current_context
    end

    def double_array(values, expected: nil)
      array = Array(values)
      raise ArgumentError, "expected #{expected} values" if expected && array.length != expected
      raise ArgumentError, "plot data cannot be empty" if array.empty?

      pointer = FFI::MemoryPointer.new(:double, array.length)
      pointer.write_array_of_double(array.map { |value| Float(value) })
      pointer
    end

    def optional_float_array(values, expected)
      return nil if values.nil?

      array = Array(values)
      raise ArgumentError, "expected #{expected} ratios" unless array.length == expected

      pointer = FFI::MemoryPointer.new(:float, array.length)
      pointer.write_array_of_float(array.map { |value| Float(value) })
      pointer
    end

    def plot_range(value)
      minimum, maximum = value ? Array(value) : [0.0, 0.0]
      range = ImGui::Native::ImPlotRange.new
      range[:Min] = Float(minimum)
      range[:Max] = Float(maximum)
      range
    end

    def null_pointer?(pointer)
      pointer.nil? || pointer.respond_to?(:null?) && pointer.null?
    end
  end
end
