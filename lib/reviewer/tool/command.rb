# frozen_string_literal: true

# Assembles tool settings into a usable command string
module Reviewer
  class Tool
    class Command
      TYPES = %i[install prepare review format].freeze

      attr_reader :settings, :command_type, :verbosity_level

      def initialize(settings, command_type: nil, verbosity_level: nil)
        @settings = settings
        @command_type = command_type
        @verbosity_level = verbosity_level
      end

      def to_s
        to_a.map(&:strip).join(' ')
      end

      def to_a
        [
          env,
          body,
          flags,
          verbosity
        ].compact
      end

      def env
        Env.new(settings.env)
      end

      def body
        # Body.new(settings.commands, command_type: command_type)
        '<command body goes here>'
      end

      def flags
        Flags.new(settings.flags)
      end

      def verbosity
        Verbosity.new(settings.quiet_flag, level: verbosity_level)
      end
    end
  end
end
