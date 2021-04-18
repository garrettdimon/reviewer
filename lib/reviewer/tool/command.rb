# frozen_string_literal: true

# Assembles tool settings into a usable command string
module Reviewer
  class Tool
    class Command
      class InvalidTypeError < StandardError; end
      class NotConfiguredError < StandardError; end

      TYPES = %i[install prepare review format].freeze

      attr_reader :settings, :command_type, :verbosity_level

      def initialize(settings, verbosity_level: nil)
        verify_command_type!

        @settings = settings
        @command_type = :review
        @verbosity_level = verbosity_level
      end

      def install(verbosity_level = :no_silence)
        command_string(:install, verbosity_level)
      end

      def prepare(verbosity_level = :no_silence)
        command_string(:prepare, verbosity_level)
      end

      def review(verbosity_level = :total_silence)
        command_string(:review, verbosity_level)

      end

      def format(verbosity_level = :no_silence)
        command_string(:format, verbosity_level)
      end

      def to_s
        to_a.map(&:strip).join(' ')
      end

      def to_a
        [
          env,
          command,
          flags,
          verbosity
        ].compact
      end

      def env
        Env.new(settings.env)
      end

      def command
        settings.commands.fetch(command_type)
      end

      def flags
        Flags.new(settings.flags)
      end

      def verbosity
        Verbosity.new(settings.quiet_flag, level: verbosity_level)
      end


      private

      def verify_command_type!
        raise InvalidTypeError, "'#{body}' is not a supported command type. (Make sure it's not a typo.)" unless TYPES.include?(body)
        raise NotConfiguredError, "The '#{body}' command is not configured for #{settings.name}.  (Make sure it's not a typo.)" unless settings.commands.key?(body)
      end

      def command_string(command_type, verbosity_level)
        @command_type = :format
        @verbosity_level = verbosity_level

        to_s
      end
    end
  end
end
