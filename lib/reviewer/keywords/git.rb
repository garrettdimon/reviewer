# frozen_string_literal: true

module Reviewer
  module Keywords
    module Git
      BASE_COMMAND = %w[git --no-pager].freeze

      # Base class for git file list commands
      class Base
        attr_reader :stdout, :stderr, :status, :exit_status

        def self.list = new.list

        def list
          @stdout, @stderr, @status = Open3.capture3(command)
          @exit_status = @status.exitstatus.to_i

          @status.success? ? to_a : raise_command_line_error
        end

        def command = (BASE_COMMAND + self.class::OPTIONS).join(' ')

        private

        def to_a = stdout.strip.empty? ? [] : stdout.split("\n")

        def raise_command_line_error
          raise SystemCallError.new("Git Error: #{stderr} (#{command})", exit_status)
        end
      end

      # Files staged for commit
      class Staged < Base
        OPTIONS = %w[diff --staged --name-only].freeze
      end

      # Files with unstaged changes
      class Unstaged < Base
        OPTIONS = %w[diff --name-only].freeze
      end

      # All files changed vs HEAD (staged + unstaged)
      class Modified < Base
        OPTIONS = %w[diff --name-only HEAD].freeze
      end

      # New files not yet tracked by git
      class Untracked < Base
        OPTIONS = %w[ls-files --others --exclude-standard].freeze
      end
    end
  end
end
