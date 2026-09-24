# frozen_string_literal: true

require 'open3'

module Reviewer
  class Arguments
    class Files
      # Finds the commit where the current work split from origin/HEAD. The `branched` keyword
      # compares against origin/HEAD only, so a missing ref or missing history is reported rather
      # than replaced with another branch.
      class BranchPoint
        # The problem, then how to fix it. An unexpected git error has no known fix, so git's own
        # message is shown instead.
        MISSING_MESSAGES = {
          origin_head: [
            "Can't compare against origin/HEAD: origin/HEAD isn't set",
            'Run `git remote set-head origin --auto`, then try again.'
          ],
          merge_base: [
            "Can't find where this work split from origin/HEAD",
            'Fetch the default branch with its history (for example, `fetch-depth: 0` in CI), then try again.'
          ],
          git_error: ["Git couldn't determine where this work split from origin/HEAD"]
        }.freeze

        # Why the branch point couldn't be found. `reason` is :origin_head when origin/HEAD isn't
        # set, :merge_base when HEAD shares no history with it (as in a shallow clone), or
        # :git_error for any other git failure, whose message is kept in `detail`.
        Missing = Struct.new(:reason, :detail) do
          # @return [String] what went wrong
          def problem = MISSING_MESSAGES.fetch(reason).first

          # @return [String, nil] how to fix it, or git's message for an unexpected error
          def fix = MISSING_MESSAGES.fetch(reason)[1] || detail

          # @return [String] the problem and its fix as one line
          def message = "#{problem}. #{fix}"
        end

        # @!attribute [r] commit
        #   @return [String, nil] the merge base with origin/HEAD, or nil when it can't be found
        # @!attribute [r] missing
        #   @return [Missing, nil] why the commit couldn't be found, or nil when it was
        attr_reader :commit, :missing

        # Resolves the branch point immediately so both attributes reflect the same git state
        #
        # @return [self]
        def initialize
          @missing = nil
          @commit = find
        end

        private

        def find
          lookup(%w[rev-parse --verify --quiet refs/remotes/origin/HEAD], when_absent: :origin_head) &&
            lookup(%w[merge-base HEAD origin/HEAD], when_absent: :merge_base)
        end

        # Git exits 1 when the ref or merge base doesn't exist. Any other failure is reported with
        # git's own message, since the fix for an absent ref wouldn't apply to it.
        def lookup(options, when_absent:)
          stdout, stderr, status = Open3.capture3('git', '--no-pager', *options)
          case status.exitstatus
          when 0 then stdout.strip
          when 1 then record_missing(when_absent, stderr)
          else record_missing(:git_error, stderr)
          end
        end

        # Only an unexpected error keeps git's message; an absent ref or merge base has a known fix
        def record_missing(reason, stderr)
          @missing = Missing.new(reason, (stderr.lines.first&.strip if reason == :git_error))
          nil
        end
      end
    end
  end
end
