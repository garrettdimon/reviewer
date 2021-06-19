# frozen_string_literal: true

module Reviewer
  module Git
    BASE_COMMAND = [
      'git',
      '--no-pager'
    ].freeze

    # Provides a convenient interface to get the list of staged files
    class Staged
      OPTIONS = [
        'diff',
        '--staged',
        '--name-only'
      ].freeze

      attr_reader :stdout, :stderr, :status, :exit_status

      def list
        @stdout, @stderr, @status = Open3.capture3(command)
        @exit_status = status.exitstatus

        raise 'Git Problem' unless status.success?

        @stdout.split("\n")
      end

      private

      def command
        command_parts.join(' ')
      end

      def command_parts
        BASE_COMMAND + OPTIONS
      end
    end
  end
end
