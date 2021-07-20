# frozen_string_literal: true

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    class Output
      attr_reader :tool, :command, :result, :timer, :logger

      def initialize(tool, command, result, timer, logger: Reviewer.logger)
        @tool = tool
        @command = command
        @result = result
        @timer = timer
        @logger = logger
      end

      def current_tool
        logger.running(tool)
      end

      def benchmark
        logger.success(timer)
      end

      def raw
        current_command = block_given? ? yield : command

        logger.command(current_command)
        logger.output do
          system(current_command)
        end
        logger.last_command(current_command)
      end

      def current_results
        logger.info "\n#{result}"
      end

      def missing_executable_guidance
        logger.failure("Missing executable for '#{tool}'")
        logger.last_command(command)
        logger.guidance('Try installing the tool:', tool.installation_command)
        logger.guidance('Read the installation guidance:', tool.settings.links&.fetch(:install, nil))
      end

      def exit_status
        logger.failure("Exit Status #{result.exit_status}")
      end
    end
  end
end
