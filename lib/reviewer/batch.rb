# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :tools, :command_type, :results

    def initialize(command_type, tools)
      @tools = tools
      @command_type = command_type
      @results = {}
    end

    def run
      tools.each do |tool|
        next unless tool.has_command?(command_type)

        runner = Runner.new(tool, command_type, verbosity)

        # Do the thing
        runner.run

        # Record the exit status
        capture_results(runner)

        # If the tool fails, stop running other tools
        break unless runner.success?
      end

      results
    end

    def self.run(**kwargs)
      new(**kwargs).run
    end

    private

    def multiple_tools?
      tools.size > 1
    end

    def verbosity
      multiple_tools? ? Command::Verbosity::TOTAL_SILENCE : Command::Verbosity::NO_SILENCE
    end

    def capture_results(runner)
      @results[runner.tool.key] = runner.exit_status
    end

    def runnable?(tool, command_type)
      case command_type
      when :install then tool.installable?
      when :prepare then tool.preparable?
      when :review then tool.reviewable?
      when :format then tool.formattable?
      else raise UnrecognizedCommandError, "The '#{command_type}' command is not a recognized command type." unless configured?
      end
    end
  end
end
