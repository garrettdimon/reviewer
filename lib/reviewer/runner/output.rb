# frozen_string_literal: true

require 'colorize'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    # Friendly API for printing the activity and results from running a command
    class Output
      SUCCESS = 'Success'
      FAILURE = 'Failure ·'
      PROMPT  = '$'
      DIVIDER = ('-' * 60).to_s

      attr_reader :tool, :command, :result, :timer, :logger

      def initialize(tool, command, result, timer, logger: Reviewer.logger)
        @tool = tool
        @command = command
        @result = result
        @timer = timer
        @logger = logger
      end

      def current_tool
        logger.info "\n#{tool.name}".bold + ' · '.light_black + tool.description
      end

      def benchmark
        success(timer)
      end

      def raw(current_command = nil)
        current_command ||= command

        logger.info "\nNow running:"
        logger.info current_command.light_black
        divider
        logger.info # Blank Lane
        system(current_command)
        divider
        last_command(current_command)
      end

      def current_results
        divider
        logger.info "\n#{result}"
        divider
      end

      def missing_executable_guidance
        failure("Missing executable for '#{tool}'")
        last_command(command)
        guidance('Try installing the tool:', tool.installation_command)
        guidance('Read the installation guidance:', tool_link(:install))
      end

      def syntax_guidance
        guidance('Selectively Ignore a Rule:', tool_link(:ignore_syntax))
        guidance('Fully Disable a Rule:', tool_link(:disable_syntax))
      end

      def exit_status
        failure("Exit Status #{result.exit_status}")
      end

      def guidance(summary, details)
        return unless details.present?

        logger.info "\n#{summary}"
        logger.info details.to_s.light_black
      end

      private

      def tool_link(key)
        tool.settings.links&.fetch(key, nil)
      end

      def last_command(cmd)
        logger.info "\nReviewer ran:"
        logger.info cmd.to_s.light_black
      end

      def divider
        logger.info # Blank Lane
        logger.info DIVIDER.light_black
      end

      def success(timer)
        message = SUCCESS.green.bold + " #{timer.elapsed_seconds}s".green
        message += " (#{timer.prep_percent}% preparation)".yellow if timer.prep?

        logger.info message
      end

      def failure(message)
        logger.error "#{FAILURE} #{message}".red.bold
      end
    end
  end
end
