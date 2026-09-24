# frozen_string_literal: true

require 'open3'

module Reviewer
  class Arguments
    class Files
      # Finds the commit where the current work split from origin/HEAD. The `branched` keyword
      # compares against origin/HEAD only, so a missing ref or missing history is reported rather
      # than replaced with another branch.
      class BranchPoint
        # @!attribute [r] commit
        #   @return [String, nil] the merge base with origin/HEAD, or nil when it can't be found
        # @!attribute [r] missing
        #   @return [Symbol, nil] :origin_head when origin/HEAD can't be resolved, :merge_base when
        #     HEAD shares no history with it (as in a shallow clone), or nil when the commit was found
        attr_reader :commit, :missing

        # Resolves the branch point immediately so both attributes reflect the same git state
        #
        # @return [self]
        def initialize
          @missing = nil
          @commit = find
        end

        # Runs a git command whose failure is an expected answer rather than an error to report
        # @param options [Array<String>] the git command options
        #
        # @return [String, nil] the trimmed output, or nil when the command fails
        def self.git(*options)
          stdout, _stderr, status = Open3.capture3('git', '--no-pager', *options)
          stdout.strip if status.success?
        end

        private

        def find
          origin_head = self.class.git('rev-parse', '--verify', '--quiet', 'refs/remotes/origin/HEAD')
          return record_missing(:origin_head) unless origin_head

          self.class.git('merge-base', 'HEAD', 'origin/HEAD') || record_missing(:merge_base)
        end

        def record_missing(piece)
          @missing = piece
          nil
        end
      end
    end
  end
end
