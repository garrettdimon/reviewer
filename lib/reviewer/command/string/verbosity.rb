# frozen_string_literal: true

module Reviewer
  class Command
    class String
      # Assembles tool settings and provided context for silencing output
      class Verbosity
        include ::Reviewer::Conversions

        SEND_TO_DEV_NULL = '> /dev/null'

        attr_reader :flag, :level

        def initialize(flag, level: Reviewer::Command::Verbosity::TOOL_SILENCE)
          @flag = String(flag)
          @level = Verbosity(level)
        end

        def to_s
          to_a.map(&:strip).join(' ').strip
        end

        def to_a
          case level.key
          when Reviewer::Command::Verbosity::TOTAL_SILENCE then [flag, SEND_TO_DEV_NULL].compact
          when Reviewer::Command::Verbosity::TOOL_SILENCE  then [flag].compact
          else []
          end
        end
      end
    end
  end
end
