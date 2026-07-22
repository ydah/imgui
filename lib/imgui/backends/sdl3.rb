# frozen_string_literal: true

module ImGui
  module Backends
    module SDL3
      module GamepadMode
        AutoFirst = 0
        AutoAll = 1
        Manual = 2
      end

      module_function

      def init_for_opengl(window, context)
        prepare_runtime!
        Backends.invoke(
          "SDL3",
          :ImGui_ImplSDL3_InitForOpenGL,
          Backends.pointer(window),
          Backends.pointer(context)
        )
      end

      def init_for_other(window)
        prepare_runtime!
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForOther, Backends.pointer(window))
      end

      def init_for_vulkan(window)
        prepare_runtime!
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForVulkan, Backends.pointer(window))
      end

      def init_for_d3d(window)
        prepare_runtime!
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForD3D, Backends.pointer(window))
      end

      def init_for_metal(window)
        prepare_runtime!
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForMetal, Backends.pointer(window))
      end

      def init_for_sdl_renderer(window, renderer)
        prepare_runtime!
        Backends.invoke(
          "SDL3",
          :ImGui_ImplSDL3_InitForSDLRenderer,
          Backends.pointer(window),
          Backends.pointer(renderer)
        )
      end

      def init_for_sdl_gpu(window)
        prepare_runtime!
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForSDLGPU, Backends.pointer(window))
      end

      def process_event(event)
        Backends.invoke("SDL3", :ImGui_ImplSDL3_ProcessEvent, Backends.pointer(event))
      end

      def new_frame
        Backends.invoke("SDL3", :ImGui_ImplSDL3_NewFrame)
      end

      def gamepad_mode=(mode)
        set_gamepad_mode(mode)
      end

      def set_gamepad_mode(mode, gamepads: nil)
        native_mode = normalize_gamepad_mode(mode)
        pointers = Array(gamepads).map { |gamepad| Backends.pointer(gamepad) }
        if native_mode == GamepadMode::Manual
          @manual_gamepads = if pointers.empty?
                               FFI::Pointer::NULL
                             else
                               FFI::MemoryPointer.new(:pointer, pointers.length).tap do |memory|
                                 memory.write_array_of_pointer(pointers)
                               end
                             end
          count = pointers.length
        else
          @manual_gamepads = nil
          count = -1
        end

        Backends.invoke(
          "SDL3",
          :ImGui_ImplSDL3_SetGamepadMode,
          native_mode,
          @manual_gamepads || FFI::Pointer::NULL,
          count
        )
      end

      def shutdown
        Backends.invoke("SDL3", :ImGui_ImplSDL3_Shutdown)
      ensure
        @manual_gamepads = nil
      end

      def normalize_gamepad_mode(mode)
        return Integer(mode) unless mode.is_a?(Symbol) || mode.is_a?(String)

        {
          auto_first: GamepadMode::AutoFirst,
          auto_all: GamepadMode::AutoAll,
          manual: GamepadMode::Manual
        }.fetch(mode.to_sym) do
          raise ArgumentError, "unknown SDL3 gamepad mode: #{mode.inspect}"
        end
      end
      private_class_method :normalize_gamepad_mode

      def prepare_runtime!
        candidates = [ENV["IMGUI_RUBY_SDL3_LIB"]]
        candidates.concat(::SDL3::Raw.ffi_libraries.map(&:name)) if defined?(::SDL3::Raw)
        candidates.concat(
          if FFI::Platform.windows?
            %w[SDL3.dll]
          elsif FFI::Platform.mac?
            %w[libSDL3.dylib SDL3.framework/SDL3 /opt/homebrew/lib/libSDL3.dylib /usr/local/lib/libSDL3.dylib]
          else
            %w[libSDL3.so.0 libSDL3.so]
          end
        )
        Backends.load_runtime_library("SDL3", candidates)
      end
      private_class_method :prepare_runtime!
    end
  end
end
