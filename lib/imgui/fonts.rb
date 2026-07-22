# frozen_string_literal: true

module ImGui
  class Fonts
    attr_reader :pointer

    def initialize(pointer)
      @pointer = pointer
    end

    def add_font_default
      ImGui.__send__(:guard_context!)
      Native.ImFontAtlas_AddFontDefault(pointer, nil)
    end

    def add_font(path, size:, glyph_ranges: nil, merge: false)
      ImGui.__send__(:guard_context!)
      config = merge ? Native.ImFontConfig_ImFontConfig : nil
      Native::ImFontConfig.new(config)[:MergeMode] = true if config
      Native.ImFontAtlas_AddFontFromFileTTF(
        pointer,
        File.expand_path(path),
        Float(size),
        config,
        glyph_ranges
      )
    ensure
      Native.ImFontConfig_destroy(config) if config
    end

    def add_font_jp(path, size:, merge: false)
      ranges = Native.ImFontAtlas_GetGlyphRangesJapanese(pointer)
      add_font(path, size: size, glyph_ranges: ranges, merge: merge)
    end

    def build
      ImGui.__send__(:guard_context!)
      Native.ImFontAtlas_Build(pointer)
    end

    def clear
      ImGui.__send__(:guard_context!)
      Native.ImFontAtlas_Clear(pointer)
    end
  end
end
