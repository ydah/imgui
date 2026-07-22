# frozen_string_literal: true

module ImGui
  module Backends
    module SDL3
      module_function

      def init_for_opengl(window, context)
        Backends.invoke(
          "SDL3",
          :ImGui_ImplSDL3_InitForOpenGL,
          Backends.pointer(window),
          Backends.pointer(context)
        )
      end

      def init_for_other(window)
        Backends.invoke("SDL3", :ImGui_ImplSDL3_InitForOther, Backends.pointer(window))
      end

      def process_event(event)
        Backends.invoke("SDL3", :ImGui_ImplSDL3_ProcessEvent, Backends.pointer(event))
      end

      def new_frame
        Backends.invoke("SDL3", :ImGui_ImplSDL3_NewFrame)
      end

      def shutdown
        Backends.invoke("SDL3", :ImGui_ImplSDL3_Shutdown)
      end
    end
  end
end
