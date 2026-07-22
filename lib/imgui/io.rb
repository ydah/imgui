# frozen_string_literal: true

module ImGui
  class IO
    BOOLEAN_FIELDS = %i[
      want_capture_mouse want_capture_keyboard want_text_input want_set_mouse_pos
      want_save_ini_settings nav_active nav_visible mouse_draw_cursor
    ].freeze
    INTEGER_FIELDS = %i[config_flags backend_flags metrics_render_vertices metrics_render_indices].freeze
    FLOAT_FIELDS = %i[delta_time framerate font_global_scale].freeze

    attr_reader :pointer

    def initialize(pointer)
      @pointer = pointer
      @native = Native::ImGuiIO.new(pointer)
      @retained_strings = {}
    end

    INTEGER_FIELDS.each do |field|
      native_field = field.to_s.split("_").map(&:capitalize).join.to_sym
      define_method(field) { @native[native_field] }
      define_method("#{field}=") { |value| @native[native_field] = Integer(value) }
    end

    FLOAT_FIELDS.each do |field|
      native_field = field.to_s.split("_").map(&:capitalize).join.to_sym
      define_method(field) { @native[native_field] }
      define_method("#{field}=") { |value| @native[native_field] = Float(value) }
    end

    BOOLEAN_FIELDS.each do |field|
      native_field = field.to_s.split("_").map(&:capitalize).join.to_sym
      define_method(field) { @native[native_field] }
      define_method("#{field}=") { |value| @native[native_field] = !!value }
    end

    def display_size
      StructValue.to_a(@native[:DisplaySize], 2)
    end

    def display_size=(value)
      @native[:DisplaySize] = StructValue.vec2(value)
    end

    def display_framebuffer_scale
      StructValue.to_a(@native[:DisplayFramebufferScale], 2)
    end

    def display_framebuffer_scale=(value)
      @native[:DisplayFramebufferScale] = StructValue.vec2(value)
    end

    def fonts
      @fonts ||= Fonts.new(@native[:Fonts])
    end

    def ini_filename
      pointer = @native[:IniFilename]
      pointer.null? ? nil : pointer.read_string
    end

    def ini_filename=(filename)
      set_retained_string(:IniFilename, filename)
    end

    def log_filename
      pointer = @native[:LogFilename]
      pointer.null? ? nil : pointer.read_string
    end

    def log_filename=(filename)
      set_retained_string(:LogFilename, filename)
    end

    private

    def set_retained_string(field, value)
      if value.nil?
        @retained_strings.delete(field)
        @native[field] = nil
        return nil
      end

      memory = FFI::MemoryPointer.from_string(String(value).encode(Encoding::UTF_8))
      @retained_strings[field] = memory
      @native[field] = memory
      value
    end
  end
end
