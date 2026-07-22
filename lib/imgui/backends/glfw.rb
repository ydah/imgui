# frozen_string_literal: true

module ImGui
  module Backends
    module Glfw
      module_function

      def init_for_opengl(window, install_callbacks: true)
        Backends.invoke(
          "GLFW",
          :ImGui_ImplGlfw_InitForOpenGL,
          Backends.pointer(window),
          !!install_callbacks
        )
      end

      def init_for_vulkan(window, install_callbacks: true)
        Backends.invoke(
          "GLFW",
          :ImGui_ImplGlfw_InitForVulkan,
          Backends.pointer(window),
          !!install_callbacks
        )
      end

      def init_for_other(window, install_callbacks: true)
        Backends.invoke(
          "GLFW",
          :ImGui_ImplGlfw_InitForOther,
          Backends.pointer(window),
          !!install_callbacks
        )
      end

      def install_callbacks(window)
        Backends.invoke("GLFW", :ImGui_ImplGlfw_InstallCallbacks, Backends.pointer(window))
      end

      def restore_callbacks(window)
        Backends.invoke("GLFW", :ImGui_ImplGlfw_RestoreCallbacks, Backends.pointer(window))
      end

      def chain_callbacks_for_all_windows=(enabled)
        Backends.invoke("GLFW", :ImGui_ImplGlfw_SetCallbacksChainForAllWindows, !!enabled)
      end

      def new_frame
        Backends.invoke("GLFW", :ImGui_ImplGlfw_NewFrame)
      end

      def shutdown
        Backends.invoke("GLFW", :ImGui_ImplGlfw_Shutdown)
      end
    end
  end
end
