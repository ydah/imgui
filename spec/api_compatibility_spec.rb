# frozen_string_literal: true

require "digest"
require "json"
require "imgui/plot"

RSpec.describe "v1 public API compatibility" do
  SURFACES = {
    "ImGui" => [ImGui, :singleton_methods],
    "ImPlot" => [ImPlot, :singleton_methods],
    "ImGui::Backends::Glfw" => [ImGui::Backends::Glfw, :singleton_methods],
    "ImGui::Backends::OpenGL3" => [ImGui::Backends::OpenGL3, :singleton_methods],
    "ImGui::Backends::SDL3" => [ImGui::Backends::SDL3, :singleton_methods],
    "ImGui::Backends::WGPU" => [ImGui::Backends::WGPU, :singleton_methods],
    "ImGui::IO" => [ImGui::IO, :public_instance_methods],
    "ImGui::Style" => [ImGui::Style, :public_instance_methods],
    "ImGui::Fonts" => [ImGui::Fonts, :public_instance_methods],
    "ImGui::DrawData" => [ImGui::DrawData, :public_instance_methods],
    "ImGui::Value" => [ImGui::Value, :public_instance_methods]
  }.freeze

  def signature_digest(object, query)
    signatures = object.public_send(query, false).sort.map do |name|
      method = query == :singleton_methods ? object.method(name) : object.instance_method(name)
      parameters = method.parameters.map { |type, argument| [type, argument].compact.join("=") }
      "#{name}:#{parameters.join(",")}"
    end
    Digest::SHA256.hexdigest(signatures.join("\n"))
  end

  it "matches the committed v1 method and signature manifest" do
    path = File.expand_path("../api/v1.json", __dir__)
    expected = JSON.parse(File.read(path)).fetch("surfaces")

    actual = SURFACES.to_h do |name, (object, query)|
      methods = object.public_send(query, false)
      [name, { "method_count" => methods.length, "sha256" => signature_digest(object, query) }]
    end

    expect(actual).to eq(expected)
  end
end
