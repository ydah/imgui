# frozen_string_literal: true

require "imgui"
require "imgui/plot"

ImGui::Native.bind_all!

puts "Native symbol audit: #{ImGui::Native.registered_functions.length} functions attached"
