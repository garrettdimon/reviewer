# frozen_string_literal: true

module Reviewer
  module Keywords
    # Git-based file list commands
    module Git
      def self.staged
        run(%w[diff --staged --name-only])
      end

      def self.unstaged
        run(%w[diff --name-only])
      end

      def self.modified
        run(%w[diff --name-only HEAD])
      end

      def self.untracked
        run(%w[ls-files --others --exclude-standard])
      end

      def self.run(options)
        command = (%w[git --no-pager] + options).join(' ')
        stdout, stderr, status = Open3.capture3(command)

        return stdout.split("\n").reject(&:empty?) if status.success?

        raise SystemCallError.new("Git Error: #{stderr} (#{command})", status.exitstatus.to_i)
      end
    end
  end
end
