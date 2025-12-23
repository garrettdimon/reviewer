# frozen_string_literal: true

module Reviewer
  module Keywords
    module Git
      # Provides a convenient interface to get the list of modified files (staged + unstaged) via Git
      class Modified
        OPTIONS = %w[diff --name-only HEAD].freeze

        attr_reader :stdout, :stderr, :status, :exit_status

        def to_a = stdout.strip.empty? ? [] : stdout.split("\n")

        def list
          @stdout, @stderr, @status = Open3.capture3(command)
          @exit_status = @status.exitstatus.to_i

          @status.success? ? to_a : raise_command_line_error
        end

        def self.list = new.list

        def command = command_parts.join(' ')

        private

        def raise_command_line_error
          message = "Git Error: #{stderr} (#{command})"
          raise SystemCallError.new(message, exit_status)
        end

        def command_parts = BASE_COMMAND + OPTIONS
      end
    end
  end
end
