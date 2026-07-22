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

    private

    def guarded_native_call(function, *arguments)
      guard_context!
      Native.public_send(function, *arguments)
    end

    def define_generated_method(ruby_name, native_name, argument_types, defaults)
      singleton_class.define_method(ruby_name) do |*arguments, **keywords|
        if arguments.length > argument_types.length
          raise ArgumentError, "wrong number of arguments (given #{arguments.length}, expected #{argument_types.length})"
        end

        values = argument_types.each_with_index.map do |(name, c_type), index|
          value = if index < arguments.length
                    arguments[index]
                  elsif keywords.key?(name.to_sym)
                    keywords.delete(name.to_sym)
                  elsif defaults.key?(name)
                    defaults.fetch(name)
                  else
                    raise ArgumentError, "missing argument: #{name}"
                  end
          convert_generated_argument(c_type, value)
        end
        raise ArgumentError, "unknown keywords: #{keywords.keys.join(", ")}" unless keywords.empty?

        guarded_native_call(native_name, *values)
      end
    end

    def convert_generated_argument(c_type, value)
      type = c_type.gsub(/\bconst\b/, "").strip
      return StructValue.vec2(value) if type == "ImVec2"
      return StructValue.vec4(value) if type == "ImVec4"
      return !!value if type == "bool"
      return Float(value) if %w[float double].include?(type)
      return Integer(value) if type.match?(/\A(?:unsigned )?(?:char|short|int|long|long long)\z/)
      return value&.to_s if type == "char*"

      value
    end

    def guard_context!
      context = Native.igGetCurrentContext
      raise NoContextError, "create an ImGui context before calling this method" if null_pointer?(context)

      key = context_key(context)
      context_threads[key] ||= Thread.current
      check_context_thread!(context)
      context
    end

    def check_context_thread!(context)
      return unless thread_checks_enabled?

      owner = context_threads[context_key(context)]
      return unless owner && owner != Thread.current

      raise ThreadError, "ImGui context belongs to thread #{owner.object_id}, not #{Thread.current.object_id}"
    end

    def null_pointer?(pointer)
      pointer.nil? || pointer == 0 || pointer.respond_to?(:null?) && pointer.null?
    end

    def context_key(context)
      context.respond_to?(:address) ? context.address : context.object_id
    end

    def context_threads
      @context_threads ||= {}
    end

    def io_views
      @io_views ||= {}
    end

    def style_views
      @style_views ||= {}
    end

    def clear_context_views(context)
      key = context_key(context)
      io_views.delete(key)
      style_views.delete(key)
    end

    def edit_scalar(function, label, value, type:, arguments:)
      guard_context!
      if value.is_a?(Value)
        require_value_type!(value, type)
        return Native.public_send(function, label, value.pointer, *arguments)
      end

      pointer = MemoryPool.pointer(type)
      pointer.put(type, 0, coerce_scalar(type, value))
      changed = Native.public_send(function, label, pointer, *arguments)
      [changed, pointer.get(type, 0)]
    end

    def edit_vector(function, label, value, count:, arguments:)
      guard_context!
      expected_type = "vec#{count}".to_sym
      if value.is_a?(Value)
        require_value_type!(value, expected_type)
        return Native.public_send(function, label, value.pointer, *arguments)
      end

      values = Array(value)
      raise ArgumentError, "expected #{count} values" unless values.length == count

      pointer = MemoryPool.pointer(:float, count)
      pointer.write_array_of_float(values.map { |item| Float(item) })
      changed = Native.public_send(function, label, pointer, *arguments)
      [changed, pointer.read_array_of_float(count)]
    end

    def vector_result(function, *arguments, count: 2)
      guard_context!
      pointer = MemoryPool.pointer(:float, count)
      Native.public_send(function, pointer, *arguments)
      pointer.read_array_of_float(count)
    end

    def require_value_type!(value, expected)
      return if value.type == expected

      raise TypeError, "expected ImGui::Value.#{expected}, got #{value.type}"
    end

    def coerce_scalar(type, value)
      case type
      when :bool then !!value
      when :int then Integer(value)
      else Float(value)
      end
    end
  end
end
