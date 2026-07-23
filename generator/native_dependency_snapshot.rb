# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

require_relative "native_dependency_lock"

module ImGuiRuby
  class NativeDependencySnapshot
    ROOT = File.expand_path("..", __dir__)
    MANIFEST_PATH = File.join(__dir__, "native-dependencies.yml")
    CACHE_ROOT = File.join(ROOT, "tmp", "vendor")
    REVISION_PATTERN = NativeDependencyLock::REVISION_PATTERN
    VerificationError = NativeDependencyLock::VerificationError

    def initialize
      @lock = NativeDependencyLock.new(MANIFEST_PATH)
      @sources = @lock.sources
    end

    def fetch!
      unless File.directory?(CACHE_ROOT)
        warn "Native dependency cache is missing; fetching pinned revisions."
        return refresh!
      end

      verify!
    rescue VerificationError => error
      warn "Native dependency cache is unavailable: #{error.message}"
      refresh!
    end

    def verify!
      @lock.validate!
      expected_files = @sources.flat_map do |name, source|
        @lock.verify_checksum!(name, source, CACHE_ROOT)
        @lock.files(name, source, CACHE_ROOT)
      end.uniq
      actual_files = all_files(CACHE_ROOT)
      unexpected = actual_files - expected_files
      raise VerificationError, "unexpected files:\n#{relative_list(unexpected)}" unless unexpected.empty?

      puts "Verified #{@sources.length} native dependency snapshots (#{actual_files.length} files)."
    end

    def refresh!(latest: false)
      resolved = {}
      FileUtils.mkdir_p(File.dirname(CACHE_ROOT))

      Dir.mktmpdir("native-dependencies-", File.dirname(CACHE_ROOT)) do |temporary_root|
        snapshot_root = File.join(temporary_root, "vendor")
        checkout_root = File.join(temporary_root, "checkouts")
        populate_snapshot!(snapshot_root, checkout_root, resolved, latest:)
        checksums = @lock.checksums(snapshot_root)
        @lock.verify_checksums!(checksums) unless latest
        replace_snapshot!(snapshot_root)
        @lock.update!(resolved, checksums) if latest
      end

      verify!
    end

    def checkout_source!(name, destination)
      source = @sources.fetch(name) { raise "unknown native dependency: #{name}" }
      path = File.expand_path(destination, ROOT)
      raise "checkout destination already exists: #{path}" if File.exist?(path)

      checkout!(source.fetch("repository"), source.fetch("revision"), path)
      puts "Checked out #{name} at #{source.fetch('revision')} to #{relative(path)}."
    end

    private

    def populate_snapshot!(snapshot_root, checkout_root, resolved, latest:)
      @sources.each do |name, source|
        revision = revision_for(name, source, resolved, latest:)
        checkout = File.join(checkout_root, name)
        checkout!(source.fetch("repository"), revision, checkout)
        resolved[name] = { revision:, checkout: }
        copy_files!(name, source, checkout, snapshot_root)
      end
    end

    def revision_for(name, source, resolved, latest:)
      return source.fetch("revision") unless latest
      return remote_revision!(source) unless source["parent"]

      parent = source.fetch("parent")
      checkout = resolved.fetch(parent.fetch("source")).fetch(:checkout)
      revision = run("git", "-C", checkout, "rev-parse", "HEAD:#{parent.fetch('path')}").strip
      raise "#{name}: parent did not resolve to a commit" unless REVISION_PATTERN.match?(revision)

      revision
    end

    def remote_revision!(source)
      ref = source.fetch("ref")
      output = run("git", "ls-remote", source.fetch("repository"), "refs/heads/#{ref}", "refs/tags/#{ref}")
      revision = output.lines.first&.split&.first
      raise "could not resolve #{source.fetch('repository')} #{ref}" unless REVISION_PATTERN.match?(revision)

      revision
    end

    def checkout!(repository, revision, destination)
      FileUtils.mkdir_p(destination)
      run("git", "-C", destination, "init", "--quiet")
      run("git", "-C", destination, "config", "core.autocrlf", "false")
      run("git", "-C", destination, "config", "core.eol", "lf")
      run("git", "-C", destination, "remote", "add", "origin", repository)
      run("git", "-C", destination, "fetch", "--quiet", "--depth", "1", "origin", revision)
      run("git", "-C", destination, "checkout", "--quiet", "--detach", "FETCH_HEAD")
    end

    def copy_files!(name, source, checkout, snapshot_root)
      source.fetch("files").each do |pattern|
        matches = Dir.glob(File.join(checkout, pattern)).select { |path| File.file?(path) }
        raise "#{name}: #{pattern} did not match upstream" if matches.empty?

        matches.each do |path|
          destination = File.join(snapshot_root, source.fetch("destination"), path.delete_prefix("#{checkout}/"))
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(path, destination)
        end
      end
    end

    def replace_snapshot!(snapshot_root)
      previous_root = "#{CACHE_ROOT}.previous"
      FileUtils.rm_rf(previous_root)
      FileUtils.mv(CACHE_ROOT, previous_root) if File.exist?(CACHE_ROOT)
      FileUtils.mv(snapshot_root, CACHE_ROOT)
      FileUtils.rm_rf(previous_root)
    rescue StandardError
      FileUtils.mv(previous_root, CACHE_ROOT) if File.exist?(previous_root) && !File.exist?(CACHE_ROOT)
      raise
    end

    def all_files(root)
      Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }
    end

    def run(*command)
      output, error, status = Open3.capture3(*command, chdir: ROOT)
      return output if status.success?

      raise "command failed (#{command.join(' ')}):\n#{error}"
    end

    def relative(path)
      path.delete_prefix("#{ROOT}/")
    end

    def relative_list(paths)
      paths.map { |path| relative(path) }.sort.join("\n")
    end
  end
end
