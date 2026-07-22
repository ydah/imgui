# frozen_string_literal: true

module ImGui
  module Backends
    module OpenGL3
      module_function

      def init(glsl_version = nil)
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_Init, glsl_version)
      end

      def new_frame
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_NewFrame)
      end

      def render_draw_data(draw_data = ImGui.draw_data)
        return if draw_data.nil?

        pointer = draw_data.respond_to?(:pointer) ? draw_data.pointer : Backends.pointer(draw_data)
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_RenderDrawData, pointer)
      end

      def create_device_objects
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_CreateDeviceObjects)
      end

      def destroy_device_objects
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_DestroyDeviceObjects)
      end

      def create_fonts_texture
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_CreateFontsTexture)
      end

      def destroy_fonts_texture
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_DestroyFontsTexture)
      end

      def shutdown
        Backends.invoke("OpenGL3", :ImGui_ImplOpenGL3_Shutdown)
      end
    end
  end
end
