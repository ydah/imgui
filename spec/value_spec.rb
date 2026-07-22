# frozen_string_literal: true

RSpec.describe ImGui::Value do
  it "stores typed scalar and vector values in stable native memory" do
    float = described_class.float(1.25)
    integer = described_class.int(4)
    boolean = described_class.bool(true)
    vector = described_class.vec3([1, 2, 3])

    expect(float.get).to eq(1.25)
    expect(integer.get).to eq(4)
    expect(boolean.get).to be(true)
    expect(vector.get).to eq([1.0, 2.0, 3.0])
    expect(float.set(2.5).get).to eq(2.5)
  end

  it "keeps a bounded NUL-terminated UTF-8 text buffer" do
    value = described_class.text("日本語", capacity: 10)

    expect(value.get).to eq("日本語")
    expect(value.get.encoding).to eq(Encoding::UTF_8)
    expect { described_class.text("", capacity: 0) }.to raise_error(ArgumentError)
  end

  it "rejects vectors with the wrong size" do
    expect { described_class.vec4([1, 2]) }.to raise_error(ArgumentError, /requires 4/)
  end
end
