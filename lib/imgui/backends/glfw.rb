# frozen_string_literal: true

module ImGui
  module Backends
    module Glfw
      module_function

      def init_for_opengl(window, install_callbacks: true)
        prepare_runtime!
        Backends.invoke(
          "GLFW",
          :ImGui_ImplGlfw_InitForOpenGL,
          Backends.pointer(window),
          !!install_callbacks
        )
      end

      def init_for_vulkan(window, install_callbacks: true)
        prepare_runtime!
        Backends.invoke(
          "GLFW",
          :ImGui_ImplGlfw_InitForVulkan,
          Backends.pointer(window),
          !!install_callbacks
        )
      end

      def init_for_other(window, install_callbacks: true)
        prepare_runtime!
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

      def prepare_runtime!
        candidates = [ENV["IMGUI_RUBY_GLFW_LIB"]]
        candidates.concat(::GLFW::API.ffi_libraries.map(&:name)) if defined?(::GLFW::API)
        candidates.concat(
          if FFI::Platform.windows?
            %w[glfw3.dll glfw3_64.dll]
          elsif FFI::Platform.mac?
            %w[libglfw.3.dylib libglfw.dylib /opt/homebrew/lib/libglfw.3.dylib /usr/local/lib/libglfw.3.dylib]
          else
            %w[libglfw.so.3 libglfw.so]
          end
        )
        Backends.load_runtime_library("GLFW", candidates)
      end
      private_class_method :prepare_runtime!

      def new_frame
        Backends.invoke("GLFW", :ImGui_ImplGlfw_NewFrame)
      end

      def shutdown
        Backends.invoke("GLFW", :ImGui_ImplGlfw_Shutdown)
      end
    end
  end
end
