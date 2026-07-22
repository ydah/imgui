# frozen_string_literal: true

module ImGui
  class << self
    def frame(platform: Backends::Glfw, renderer: Backends::OpenGL3)
      renderer.new_frame
      platform.new_frame
      new_frame
      result = yield
      render
      renderer.render_draw_data(draw_data)
      result
    end

    def easy_loop(window, platform: Backends::Glfw, renderer: Backends::OpenGL3)
      raise ArgumentError, "a UI block is required" unless block_given?

      until window.should_close?
        ::GLFW.poll_events if defined?(::GLFW) && ::GLFW.respond_to?(:poll_events)
        frame(platform: platform, renderer: renderer) { yield }
        window.swap_buffers if window.respond_to?(:swap_buffers)
      end
    end
  end
end
