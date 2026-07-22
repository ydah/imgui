# frozen_string_literal: true

module ImGui
  class Value
    TYPES = {
      bool: [:bool, 1],
      float: [:float, 1],
      int: [:int, 1],
      vec2: [:float, 2],
      vec3: [:float, 3],
      vec4: [:float, 4]
    }.freeze

    attr_reader :pointer, :type, :capacity

    class << self
      TYPES.each_key do |type|
        define_method(type) { |initial| new(type, initial) }
      end

      def text(initial = "", capacity: nil)
        new(:text, initial, capacity: capacity)
      end
    end

    def initialize(type, initial, capacity: nil)
      @type = type.to_sym
      if @type == :text
        initialize_text(initial, capacity)
      else
        initialize_numeric(initial)
      end
    end

    def get
      return pointer.read_string.force_encoding(Encoding::UTF_8) if type == :text

      ffi_type, count = TYPES.fetch(type)
      return pointer.get(ffi_type, 0) if count == 1

      pointer.public_send("read_array_of_#{ffi_type}", count)
    end

    def set(value)
      if type == :text
        write_text(value)
      else
        write_numeric(value)
      end
      self
    end

    def text?
      type == :text
    end

    private

    def initialize_text(initial, requested_capacity)
      string = String(initial).encode(Encoding::UTF_8)
      @capacity = Integer(requested_capacity || [string.bytesize + 1, 256].max)
      raise ArgumentError, "capacity must be positive" unless @capacity.positive?

      @pointer = FFI::MemoryPointer.new(:char, @capacity, true)
      write_text(string)
    end

    def initialize_numeric(initial)
      ffi_type, count = TYPES.fetch(type) do
        raise ArgumentError, "unknown value type: #{type.inspect}"
      end
      @capacity = FFI.type_size(ffi_type) * count
      @pointer = FFI::MemoryPointer.new(ffi_type, count)
      write_numeric(initial)
    end

    def write_text(value)
      bytes = String(value).encode(Encoding::UTF_8).byteslice(0, capacity - 1)
      pointer.clear
      pointer.put_bytes(0, bytes)
    end

    def write_numeric(value)
      ffi_type, count = TYPES.fetch(type)
      if count == 1
        pointer.put(ffi_type, 0, coerce_scalar(value))
        return
      end

      values = Array(value)
      raise ArgumentError, "#{type} requires #{count} values" unless values.length == count

      pointer.public_send("write_array_of_#{ffi_type}", values.map { |item| coerce_scalar(item) })
    end

    def coerce_scalar(value)
      case type
      when :bool then !!value
      when :int then Integer(value)
      else Float(value)
      end
    end
  end
end
