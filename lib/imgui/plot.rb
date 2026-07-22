# frozen_string_literal: true

require "imgui"

require_relative "plot/native/typedefs"
require_relative "plot/native/enums"
require_relative "plot/native/structs"
require_relative "plot/native/functions"
require_relative "plot/api"

module ImPlot
  Native = ImGui::Native
end
