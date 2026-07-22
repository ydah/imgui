# imgui-ruby

Ruby bindings for [Dear ImGui](https://github.com/ocornut/imgui) through
[cimgui](https://github.com/cimgui/cimgui) and FFI. The binding targets Dear
ImGui 1.91.9 from the docking branch and is generated from cimgui metadata.

The API has three layers:

```ruby
ImGui::Native.igButton("OK", ImGui::Native::ImVec2.new) # generated C API
ImGui.button("OK")                                      # idiomatic Ruby API
ImGui.window("Debug") { ImGui.text("hello") }           # exception-safe DSL
```

## Installation

Add the gem to your bundle:

```bash
bundle add imgui-ruby
```

The source gem needs CMake and a C++17 compiler. A platform gem contains a
prebuilt `libcimgui_ruby` and does not compile during installation. The only
required runtime dependency is `ffi`; `glfw-ruby` and `sdl3` are optional and
needed only by their respective backends.

To use a custom native build, set its full path before requiring the gem:

```bash
IMGUI_RUBY_LIB=/opt/imgui/libcimgui_ruby.so ruby app.rb
```

## Basic OpenGL/GLFW loop

```ruby
require "imgui"
require "glfw"

context = ImGui.create_context
io = ImGui.io
io.config_flags |= ImGui::ConfigFlags::DockingEnable
io.fonts.add_font_jp("assets/NotoSansJP-Regular.ttf", size: 18)

ImGui::Backends::Glfw.init_for_opengl(window.handle, install_callbacks: true)
ImGui::Backends::OpenGL3.init("#version 330")

until window.should_close?
  GLFW.poll_events
  ImGui::Backends::OpenGL3.new_frame
  ImGui::Backends::Glfw.new_frame
  ImGui.new_frame

  ImGui.window("Stats") do
    ImGui.text("fps: %.1f", io.framerate)
    ImGui.separator
    ImGui.button("Reset")
  end

  ImGui.render
  ImGui::Backends::OpenGL3.render_draw_data(ImGui.draw_data)
  window.swap_buffers
end

ImGui::Backends::OpenGL3.shutdown
ImGui::Backends::Glfw.shutdown
ImGui.destroy_context(context)
```

`ImGui.frame` performs the three `new_frame` calls, yields the UI block, then
renders DrawData. `ImGui.easy_loop` additionally owns the window loop and swaps
buffers when the window object supports it.

## Values and output arguments

Passing a Ruby value returns `[changed, value]`:

```ruby
changed, speed = ImGui.slider_float("Speed", speed, 0.0, 10.0)
changed, tint = ImGui.color_edit3("Tint", tint)
```

`ImGui::Value` owns stable native memory and is updated in place:

```ruby
speed = ImGui::Value.float(1.0)
open = ImGui::Value.bool(true)
name = ImGui::Value.text("Player", capacity: 256)

ImGui.slider_float("Speed", speed, 0.0, 10.0)
ImGui.checkbox("Open", open)
ImGui.input_text("Name", name)
```

The available types are `bool`, `int`, `float`, `vec2`, `vec3`, `vec4`, and
`text`.

## Block DSL

Begin/End pairs have different native contracts. The DSL calls the matching
End or Pop under the correct condition and uses `ensure`, so Ruby exceptions do
not corrupt the ImGui stack.

```ruby
ImGui.window("Inspector") do
  ImGui.menu_bar do
    ImGui.menu("File") { ImGui.menu_item("Close") }
  end

  ImGui.tree_node("Renderer") do
    ImGui.style_color(ImGui::Col::Text, [1, 0.4, 0.2, 1]) do
      ImGui.text("draw calls: %d", draw_calls)
    end
  end
end
```

Blockless calls return the native Begin result for manual control. Close them
with the matching method, such as `end_window`, `end_table`, `tree_pop`, or the
generic `close_scope`. A mismatched close raises `ImGui::StackError`.

## Fonts and retained strings

`io.fonts.add_font_jp` uses Dear ImGui's Japanese glyph range. Pass
`merge: true` to merge an icon font. Dear ImGui retains `IniFilename` and
`LogFilename` pointers, so assign them through `ImGui.ini_filename=` or the IO
wrapper; imgui-ruby retains the backing memory for the context lifetime.

```ruby
ImGui.ini_filename = "settings/imgui.ini"
ImGui.io.log_filename = nil
```

## Thread safety

Contexts are owned by the thread that first uses or creates them. Layer 2 and
the DSL raise `ImGui::ThreadError` when a context is used from another thread.
`ImGui.unsafe_allow_threads!` disables this guard for applications that provide
their own synchronization; `ImGui.enforce_thread_safety!` restores it.

## Backends

The native build can include GLFW, OpenGL3, and SDL3 wrappers. Select source
build backends with a comma-separated environment variable:

```bash
IMGUI_RUBY_BACKENDS=glfw,opengl3 bundle exec rake native:build
```

Backend symbols are resolved on first use, so a core-only library remains
usable for headless operation. Calling a backend omitted from the native
library raises `ImGui::BackendUnavailableError`. The WGPU module currently
reports that the stagecraft function-table bridge belongs to the v0.3
milestone instead of attempting an unsafe ABI call.

## Development

Initialize the pinned cimgui and Dear ImGui submodules, install dependencies,
then run the Ruby and native suites:

```bash
git submodule update --init --recursive
bundle install
bundle exec rake
bundle exec rake native:spec
```

Regenerate all committed Native files and the snake_case Layer 2 surface with:

```bash
bundle exec rake generate
```

`native:spec` builds cimgui and executes two real headless frames. To build the
source gem use `bundle exec rake build`; `bundle exec rake gem:platform` builds
a gem containing the native library for the current platform.

## License

imgui-ruby, Dear ImGui, and cimgui are available under the MIT License.
