# frozen_string_literal: true

require "digest"
require "yaml"

module ImGuiRuby
  class NativeDependencyLock
    class VerificationError < StandardError; end

    REVISION_PATTERN = /\A[0-9a-f]{40}\z/
    CHECKSUM_PATTERN = /\Asha256:[0-9a-f]{64}\z/

    attr_reader :sources

    def initialize(path)
      @path = path
      @manifest = YAML.safe_load_file(path, aliases: false)
      @sources = @manifest.fetch("sources")
    end

    def validate!
      raise VerificationError, "unsupported manifest" unless @manifest["schema"] == 1

      @sources.each do |name, source|
        raise VerificationError, "#{name}: invalid revision" unless REVISION_PATTERN.match?(source.fetch("revision"))
        raise VerificationError, "#{name}: invalid checksum" unless CHECKSUM_PATTERN.match?(source.fetch("checksum"))
      end
    end

    def files(name, source, root)
      base = File.join(root, source.fetch("destination"))
      source.fetch("files").flat_map do |pattern|
        matches = Dir.glob(File.join(base, pattern)).select { |path| File.file?(path) }
        raise VerificationError, "#{name}: #{pattern} did not match a file" if matches.empty?

        matches
      end
    end

    def verify_checksum!(name, source, root)
      return if source.fetch("checksum") == checksum(name, source, root)

      raise VerificationError, "#{name}: checksum mismatch"
    end

    def checksums(root)
      @sources.to_h { |name, source| [name, checksum(name, source, root)] }
    end

    def verify_checksums!(checksums)
      @sources.each do |name, source|
        next if source.fetch("checksum") == checksums.fetch(name)

        raise VerificationError, "#{name}: downloaded content checksum mismatch"
      end
    end

    def update!(resolved, checksums)
      resolved.each do |name, data|
        source = @sources.fetch(name)
        source["revision"] = data.fetch(:revision)
        source["checksum"] = checksums.fetch(name)
      end
      File.write(@path, YAML.dump(@manifest))
    end

    private

    def checksum(name, source, root)
      base = File.join(root, source.fetch("destination"))
      digest = Digest::SHA256.new
      files(name, source, root).sort.each do |path|
        digest << path.delete_prefix("#{base}/") << "\0" << File.binread(path) << "\0"
      end
      "sha256:#{digest.hexdigest}"
    end
  end
end
