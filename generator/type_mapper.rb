# frozen_string_literal: true

module ImGuiRuby
  module Generator
    class TypeMapper
      PRIMITIVES = {
        "void" => ":void",
        "bool" => ":bool",
        "char" => ":char",
        "signed char" => ":char",
        "unsigned char" => ":uchar",
        "short" => ":short",
        "unsigned short" => ":ushort",
        "int" => ":int",
        "unsigned int" => ":uint",
        "long" => ":long",
        "unsigned long" => ":ulong",
        "long long" => ":long_long",
        "unsigned long long" => ":ulong_long",
        "float" => ":float",
        "double" => ":double",
        "size_t" => ":size_t",
        "ptrdiff_t" => ":ptrdiff_t"
      }.freeze

      def initialize(typedefs:, structs:, enum_types:)
        @typedefs = typedefs
        @structs = structs
        @enum_types = enum_types
      end

      def ffi_type(c_type, member: nil)
        type = normalize(c_type)
        array_size = member&.fetch("size", nil) || array_size_from(type)
        type = type.sub(/\s*\[[^\]]+\]\z/, "") if array_size
        mapped = map_scalar(type)
        return mapped unless array_size

        "[#{mapped}, #{array_size}]"
      end

      def typedef_type(c_type)
        type = normalize(c_type)
        return ":pointer" if pointer?(type) || callback?(type) || type.include?("<")
        return PRIMITIVES.fetch(type) if PRIMITIVES.key?(type)
        return ":int" if enum_type?(type)

        resolved = @typedefs[type]
        return typedef_type(resolved) if resolved && resolved != c_type

        ":pointer"
      end

      private

      def map_scalar(type)
        return ":string" if type.match?(/\A(?:const\s+)?char\s*\*\z/)
        return ":pointer" if pointer?(type) || callback?(type)

        bare = type.sub(/\Aconst\s+/, "").strip
        return PRIMITIVES.fetch(bare) if PRIMITIVES.key?(bare)
        return ":int" if enum_type?(bare)
        return "#{bare}.by_value" if @structs.key?(bare)

        resolved = @typedefs[bare]
        return typedef_type(resolved) if resolved

        ":pointer"
      end

      def normalize(c_type)
        c_type.to_s
          .gsub(/\bvolatile\b/, "")
          .gsub(/\bstruct\s+/, "")
          .gsub(/\s+/, " ")
          .strip
          .sub(/;\z/, "")
      end

      def pointer?(type)
        type.include?("*") || type.end_with?("&")
      end

      def callback?(type)
        type.include?("(*)") || type.include?("(*")
      end

      def enum_type?(type)
        @enum_types.include?(type) || @typedefs[type] == "int" && type.match?(/Flags|ImGuiCol\z|ImGuiKey\z/)
      end

      def array_size_from(type)
        match = type.match(/\[([^\]]+)\]\z/)
        match && match[1]
      end
    end
  end
end
