# frozen_string_literal: true

module ImGui
  module Backends
    module WGPU
      module_function

      def init(**)
        raise BackendUnavailableError,
              "WGPU requires the stagecraft function-table bridge planned for imgui-ruby 0.3"
      end

      def new_frame
        raise BackendUnavailableError,
              "WGPU requires the stagecraft function-table bridge planned for imgui-ruby 0.3"
      end

      def render_draw_data(*)
        raise BackendUnavailableError,
              "WGPU requires the stagecraft function-table bridge planned for imgui-ruby 0.3"
      end

      def shutdown
        raise BackendUnavailableError,
              "WGPU requires the stagecraft function-table bridge planned for imgui-ruby 0.3"
      end
    end
  end
end
