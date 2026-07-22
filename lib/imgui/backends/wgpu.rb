# frozen_string_literal: true

module ImGui
  module Native
    attach_function :imgui_ruby_wgpu_required_function_count, [], :size_t
    attach_function :imgui_ruby_wgpu_required_function_name, [:size_t], :string
    attach_function :imgui_ruby_wgpu_set_function, [:string, :pointer], :bool
    attach_function :imgui_ruby_wgpu_bridge_ready, [], :bool
    attach_function :imgui_ruby_wgpu_bridge_error, [], :string
    attach_function :imgui_ruby_wgpu_init, [:pointer, :int, :int, :int, :uint, :uint, :bool], :bool
    attach_function :imgui_ruby_wgpu_shutdown, [], :void
    attach_function :imgui_ruby_wgpu_new_frame, [], :void
    attach_function :imgui_ruby_wgpu_render_draw_data, [:pointer, :pointer], :void
    attach_function :imgui_ruby_wgpu_render_draw_data_to_view, [:pointer, :pointer, :pointer], :bool
  end

  module Backends
    module WGPU
      UNDEFINED_TEXTURE_FORMAT = 0
      DEFAULT_SAMPLE_MASK = 0xffff_ffff

      module_function

      def init(
        device:,
        queue: nil,
        render_target_format:,
        depth_format: nil,
        frames_in_flight: 3,
        sample_count: 1,
        sample_mask: DEFAULT_SAMPLE_MASK,
        alpha_to_coverage: false,
        function_table: nil,
        library_path: nil
      )
        validate_init_options!(frames_in_flight, sample_count)
        source = resolve_function_source(device, function_table, library_path)
        configure_function_table!(source)

        # The official backend obtains the default queue from the device. Accepting
        # queue keeps the stagecraft integration signature stable and validates it
        # when supplied, without retaining an unnecessary second queue reference.
        Backends.pointer(queue) if queue
        Backends.invoke(
          "WGPU",
          :imgui_ruby_wgpu_init,
          Backends.pointer(device),
          Integer(frames_in_flight),
          Integer(render_target_format),
          depth_format.nil? ? UNDEFINED_TEXTURE_FORMAT : Integer(depth_format),
          Integer(sample_count),
          Integer(sample_mask),
          !!alpha_to_coverage
        )
      end

      def new_frame
        Backends.invoke("WGPU", :imgui_ruby_wgpu_new_frame)
      end

      def render_draw_data(draw_data, encoder, target_view = nil)
        return if draw_data.nil?

        data_pointer = draw_data.respond_to?(:pointer) ? draw_data.pointer : Backends.pointer(draw_data)
        encoder_pointer = Backends.pointer(encoder)
        return Backends.invoke(
          "WGPU",
          :imgui_ruby_wgpu_render_draw_data,
          data_pointer,
          encoder_pointer
        ) unless target_view

        Backends.invoke(
          "WGPU",
          :imgui_ruby_wgpu_render_draw_data_to_view,
          data_pointer,
          encoder_pointer,
          Backends.pointer(target_view)
        )
      end

      def shutdown
        Backends.invoke("WGPU", :imgui_ruby_wgpu_shutdown)
      end

      def available?
        Native.load!
        Native.imgui_ruby_wgpu_bridge_error
        true
      rescue LibraryLoadError, MissingSymbolError
        false
      end

      def resolve_function_source(device, explicit, library_path)
        return explicit if explicit

        return device.function_table if device.respond_to?(:function_table)
        return device.native_library if device.respond_to?(:native_library)

        if library_path
          library = FFI::DynamicLibrary.open(
            File.expand_path(library_path),
            FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_LOCAL
          )
          retained_libraries << library
          return library
        end

        if defined?(::WGPU::Native) && ::WGPU::Native.respond_to?(:ffi_libraries)
          library = ::WGPU::Native.ffi_libraries.find { |candidate| function_pointer(candidate, "wgpuDeviceCreateBuffer") }
          return library if library
        end

        raise BackendUnavailableError, <<~MESSAGE.strip
          WGPU needs a native function table. Load the wgpu/stagecraft runtime
          first, pass function_table:, or pass library_path: to its native library.
        MESSAGE
      end
      private_class_method :resolve_function_source

      def configure_function_table!(source)
        required_function_names.each do |name|
          pointer = function_pointer(source, name)
          raise BackendUnavailableError, "WebGPU function is unavailable: #{name}" unless pointer

          configured = Backends.invoke("WGPU", :imgui_ruby_wgpu_set_function, name, pointer)
          next if configured

          raise BackendUnavailableError, "WGPU function-table bridge rejected #{name}"
        end
        return true if Backends.invoke("WGPU", :imgui_ruby_wgpu_bridge_ready)

        raise BackendUnavailableError, "WGPU function-table bridge failed: #{Native.imgui_ruby_wgpu_bridge_error}"
      end
      private_class_method :configure_function_table!

      def required_function_names
        count = Backends.invoke("WGPU", :imgui_ruby_wgpu_required_function_count)
        Array.new(count) do |index|
          Backends.invoke("WGPU", :imgui_ruby_wgpu_required_function_name, index)
        end
      end
      private_class_method :required_function_names

      def function_pointer(source, name)
        value = if source.respond_to?(:fetch)
                  source.fetch(name) { source.fetch(name.to_sym, nil) }
                elsif source.respond_to?(:find_function)
                  source.find_function(name)
                elsif source.respond_to?(:function_address)
                  source.function_address(name)
                elsif source.respond_to?(name)
                  source.method(name)
                end
        return if value.nil?
        return FFI::Pointer.new(value.address) if value.respond_to?(:address)

        Backends.pointer(value)
      rescue FFI::NotFoundError
        nil
      end
      private_class_method :function_pointer

      def retained_libraries
        @retained_libraries ||= []
      end
      private_class_method :retained_libraries

      def validate_init_options!(frames_in_flight, sample_count)
        raise ArgumentError, "frames_in_flight must be positive" unless Integer(frames_in_flight).positive?
        raise ArgumentError, "sample_count must be positive" unless Integer(sample_count).positive?
      end
      private_class_method :validate_init_options!
    end
  end
end
