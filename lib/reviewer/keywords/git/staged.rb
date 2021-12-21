# frozen_string_literal: true

module Reviewer
  module Keywords
    module Git
      # Provides a convenient interface to get the list of staged files via Git
      class Staged
        OPTIONS = [
          'diff',
          '--staged',
          '--name-only'
        ].freeze

        attr_reader :stdout, :stderr, :status, :exit_status

        def to_a
          stdout.strip.empty? ? [] : stdout.split("\n")
        end

        # Gets the list of staged files
        #
        # @example Get the list of files
        #   staged.list #=> ['/Code/example.rb', '/Code/run.rb']
        #
        # @return [Array<String>] the array of staged filenames as strings
        def list
          @stdout, @stderr, @status = Open3.capture3(command)
          @exit_status = @status.exitstatus.to_i

          @status.success? ? to_a : raise_command_line_error
        end

        # Convenience method for retrieving the list of staged files since there's no parameters
        #   for an initializer.
        #
        # @example Get the list of files
        #   Reviewer::Keywords::Git::Staged.list #=> ['/Code/example.rb', '/Code/run.rb']
        #
        # @return [Array<String>] the array of staged filenames as strings
        def self.list
          new.list
        end

        # Assembles the pieces of the command that gets the list of staged files
        #
        # @return [String] the full command to run to retrieve the list of staged files
        def command
          command_parts.join(' ')
        end

        private

        def raise_command_line_error
          message = "Git Error: #{stderr} (#{command})"
          raise SystemCallError.new(message, exit_status)
        end

        def command_parts
          BASE_COMMAND + OPTIONS
        end
      end
    end
  end
end
