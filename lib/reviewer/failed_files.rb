# frozen_string_literal: true

module Reviewer
  # Extracts file paths from tool stdout/stderr output so that subsequent re-runs
  # can be scoped to only the files that had issues.
  class FailedFiles
    # Matches path-like tokens at or near the start of a line, allowing leading
    # whitespace for tools that indent output (reek groupings, rspec nesting).
    # Supports any file extension so non-Ruby tools (eslint, stylelint) also work.
    # File.exist? in extract_paths guards against false positives.
    #
    #   lib/foo.rb:45:3: C: Style/... (rubocop)
    #   test/foo_test.rb:45 (minitest)
    #   lib/foo.rb -- message (reek)
    #   src/app.js:10:5: error ... (eslint)
    FILE_PATH_PATTERN = /^\s*(\S+\.\w+)(?::\d| -- )/

    attr_reader :stdout, :stderr

    def initialize(stdout, stderr)
      @stdout = stdout
      @stderr = stderr
    end

    def to_a
      matched_paths.select { |path| File.exist?(path) }.uniq
    end

    # All regex-matched paths before filesystem filtering
    def matched_paths
      combined_output.scan(FILE_PATH_PATTERN).flatten
    end

    private

    def combined_output
      [stdout, stderr].compact.join("\n")
    end
  end
end
