# frozen_string_literal: true

module Reviewer
  module Keywords
    # Git-based file list commands
    module Git
      # Returns files staged for commit
      #
      # @return [Array<String>] list of staged file paths
      def self.staged
        run(%w[diff --staged --name-only])
      end

      # Returns files with unstaged changes
      #
      # @return [Array<String>] list of modified but unstaged file paths
      def self.unstaged
        run(%w[diff --name-only])
      end

      # Returns all modified files (staged and unstaged)
      #
      # @return [Array<String>] list of all modified file paths
      def self.modified
        run(%w[diff --name-only HEAD])
      end

      # Returns untracked files not in .gitignore
      #
      # @return [Array<String>] list of untracked file paths
      def self.untracked
        run(%w[ls-files --others --exclude-standard])
      end

      # Executes a git command and returns the output as an array of lines
      # @param options [Array<String>] the git command options
      #
      # @return [Array<String>] the output lines from the command
      # @raise [SystemCallError] if the git command fails
      def self.run(options)
        command = (%w[git --no-pager] + options).join(' ')
        stdout, stderr, status = Open3.capture3(command)

        return stdout.split("\n").reject(&:empty?) if status.success?

        raise SystemCallError.new("Git Error: #{stderr} (#{command})", status.exitstatus.to_i)
      end
    end
  end
end
