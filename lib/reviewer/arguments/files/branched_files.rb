# frozen_string_literal: true

require 'open3'

module Reviewer
  class Arguments
    class Files
      # Selects the files for the `branched` keyword: every file that differs from origin/HEAD since
      # this work split from it, including uncommitted and new files. It compares against origin/HEAD
      # only, so when any git step fails, `missing` says why and no files are selected rather than
      # substituting another branch or reviewing nothing.
      class BranchedFiles
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
          git_error: ["Git couldn't list the files that differ from origin/HEAD"]
        }.freeze

        # Why the files couldn't be selected. `reason` is :origin_head when origin/HEAD isn't set,
        # :merge_base when HEAD shares no history with it (as in a shallow clone), or :git_error for
        # any other git failure, whose message is kept in `detail`.
        Missing = Struct.new(:reason, :detail) do
          # @return [String] what went wrong
          def problem = MISSING_MESSAGES.fetch(reason).first

          # @return [String, nil] how to fix it, or git's message for an unexpected error
          def fix = MISSING_MESSAGES.fetch(reason)[1] || detail

          # @return [String] the problem and its fix as one line
          def message = "#{problem}. #{fix}"
        end

        # @!attribute [r] files
        #   @return [Array<String>] the selected paths, empty when `missing` is set
        # @!attribute [r] missing
        #   @return [Missing, nil] why the files couldn't be selected, or nil when they were
        attr_reader :files, :missing

        # Runs every git step immediately so both attributes reflect the same git state
        #
        # @return [self]
        def initialize
          @missing = nil
          @files = select || []
        end

        private

        def select
          merge_base = find_merge_base
          changed = merge_base && lookup(%W[diff --name-only #{merge_base}])
          untracked = changed && lookup(%w[ls-files --others --exclude-standard])
          return unless untracked

          (changed.split("\n") + untracked.split("\n")).reject(&:empty?)
        end

        def find_merge_base
          lookup(%w[rev-parse --verify --quiet refs/remotes/origin/HEAD], when_absent: :origin_head) &&
            lookup(%w[merge-base HEAD origin/HEAD], when_absent: :merge_base)
        end

        # Git exits 1 when a ref or merge base doesn't exist. Any other failure is reported with git's
        # own message, since the fix for an absent ref wouldn't apply to it. Output is read as UTF-8
        # with paths unescaped, like the other git keywords.
        def lookup(options, when_absent: :git_error)
          stdout, stderr, status = Open3.capture3('git', '-c', 'core.quotePath=false', '--no-pager', *options)
          case status.exitstatus
          when 0 then Shell::Result.decode(stdout).strip
          when 1 then record_missing(when_absent, stderr)
          else record_missing(:git_error, stderr)
          end
        end

        # Only an unexpected error keeps git's message; an absent ref or merge base has a known fix
        def record_missing(reason, stderr)
          detail = (Shell::Result.decode(stderr).lines.first&.strip if reason == :git_error)
          @missing = Missing.new(reason, detail)
          nil
        end
      end
    end
  end
end
