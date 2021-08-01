# frozen_string_literal: true

module Reviewer
  module Commands
    # Provides a structure for running review commands and sharing results
    class Review
      include Conversions

      attr_reader :tool

      def initialize(tool, verbosity = Verbosity::TOTAL_SILENCE)
        @tool = tool
        @verbosity = Verbosity(verbosity)
      end

      def verbosity
        @verbosity
      end

      def verbosity=(verbosity)
        @verbosity = Verbosity(verbosity)
        @command.verbosity = @verbosity
      end

      def to_s
        if seed_substitution?
          # Store the seed for reference
          Reviewer.history.set(tool.key, :last_seed, seed)

          # Update the string with the memoized seed value
          command.string.gsub(SEED_SUBSTITUTION_VALUE, seed.to_s)
        else
          # Otherwise, the string is good as is
          command.string
        end
      end

      def seed_substitution?
        command.string.include?(SEED_SUBSTITUTION_VALUE)
      end

      # Generates a seed that can be re-used across runs so that the results are consistent across
      # related runs for tools that would otherwise change the seed automatically every run.
      # Since not all tools will use the seed, there's no need to generate it in the initializer.
      # Instead, it's memoized if it's used.
      #
      # @return [Integer] a random integer to pass to tools that use seeds
      def seed
        @seed ||= Random.rand(100_000)
      end

      # def run
      #   output.tool_summary(tool)

      #   case verbosity
      #   when :total_silence then run_quietly_and_benchmark
      #   when :no_silence then run_verbosely
      #   end

      #   exit_status
      # end

      # def success?
      #   result.success?(max_exit_status: tool.max_exit_status)
      # end

      # private

      # def batch_run
      #   run_quietly_and_benchmark
      #   show_results
      # end

      # def needs_prep?
      #   tool.prepare_command? && tool.stale?
      # end

      # def run_quietly_and_benchmark
      #   shell.tap do |shell|
      #     shell.preparation = preparation_command
      #     shell.command = review_command(:total_silence)
      #   end.run_and_benchmark
      # end

      # def run_verbosely
      #   command = review_command(:no_silence)

      #   output.current_command(command)
      #   output.divider

      #   # Using the shell here would capture the output as plain text and strip it of any color or
      #   # or special characters. So it runs the full command with no quiet optiosn directly in its
      #   # full glory and leaves the tool's own output formatting in tact
      #   shell.direct(command)

      #   output.divider
      #   output.last_command(command)
      # end

      # def review_command(verbosity = nil)
      #   tool.review_command(verbosity, seed: seed)
      # end

      # def preparation_command
      #   return nil unless needs_prep?

      #   tool.last_prepared_at = Time.current
      #   tool.preparation_command
      # end

      # def show_results
      #   if success?
      #     output.success(timer)
      #   else
      #     output.failure("Exit Status #{exit_status} · #{result}")
      #     show_guidance
      #   end
      # end
    end
  end
end
