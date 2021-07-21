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
        running(tool)
      end

      def benchmark
        success(timer)
      end

      def raw(current_command = nil)
        current_command ||= command

        now_running(current_command)
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
        guidance('Read the installation guidance:', tool.settings.links&.fetch(:install, nil))
      end

      def syntax_guidance
        guidance('Syntax for Selectively Ignoring a Rule:', tool.settings.links&.fetch(:ignore_syntax, nil))
        guidance('Syntax for Disabling Rules:', tool.settings.links&.fetch(:disable_syntax, nil))
      end

      def exit_status
        failure("Exit Status #{result.exit_status}")
      end

      private

      def running(tool)
        logger.info "\n#{tool.name}".bold + ' · '.light_black + tool.description
      end

      def now_running(cmd)
        logger.info "\nNow running:"
        logger.info cmd.to_s.light_black
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

      def guidance(summary, details)
        return unless details.present?

        logger.info "\n#{summary}" if summary
        logger.info details.to_s.light_black if details
      end
    end
  end
end
