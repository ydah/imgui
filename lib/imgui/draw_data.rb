# frozen_string_literal: true

module ImGui
  class DrawData
    attr_reader :pointer

    def initialize(pointer)
      @pointer = pointer
      @native = Native::ImDrawData.new(pointer)
    end

    def valid?
      @native[:Valid]
    end

    def command_lists_count
      @native[:CmdListsCount]
    end

    def total_index_count
      @native[:TotalIdxCount]
    end

    def total_vertex_count
      @native[:TotalVtxCount]
    end

    alias total_idx_count total_index_count
    alias total_vtx_count total_vertex_count

    def display_pos
      StructValue.to_a(@native[:DisplayPos], 2)
    end

    def display_size
      StructValue.to_a(@native[:DisplaySize], 2)
    end

    def framebuffer_scale
      StructValue.to_a(@native[:FramebufferScale], 2)
    end
  end
end
