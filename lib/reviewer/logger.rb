# frozen_string_literal: true

require 'colorize'

module Reviewer
  # Clean formatter for logging to $stdout
  class StandardOutFormatter < ::Logger::Formatter
    # Overrides ::Logger::Formatter `call` to more present output more concisely
    # @param _severity [Logger::Severity] Unused - Logger severity for etnry
    # @param _time [DateTime] Unused - Timestamp for entry
    # @param _progname [String] Unused - Name of the current program for entry
    # @param message [String] The string to print to $stdout
    #
    # @return [type] [description]
    def call(_severity, _time, _progname, message)
      "#{message}\n"
    end
  end

  # Logger for $stdout
  class Logger < ::Logger
    SUCCESS = 'Success'
    FAILURE = 'Failure ·'
    PROMPT  = '$'
    DIVIDER = ('-' * 60).to_s

    def initialize(formatter = StandardOutFormatter.new)
      super($stdout)
      @formatter = formatter
    end

    def running(tool)
      info "\n#{tool.name}".bold + ' · '.light_black + tool.description
    end

    def command(cmd)
      info "\nNow running:"
      info cmd.to_s.light_black
    end

    def last_command(cmd)
      info "\nReviewer ran:"
      info cmd.to_s.light_black
    end

    def divider
      info DIVIDER.light_black
    end

    def output
      info # Blank Lane
      divider
      yield
      divider
    end

    def success(elapsed_time, prep_time = nil)
      info SUCCESS.green.bold + timing(elapsed_time, prep_time)
    end

    def failure(message)
      error "#{FAILURE} #{message}".red.bold
    end

    def total_time(elapsed_time)
      info "\nTotal Time ".white + "#{elapsed_time.round(1)}s".bold
    end

    def guidance(summary, details)
      return unless details.present?

      info "\n#{summary}" if summary
      info details.to_s.light_black if details
    end

    private

    def timing(elapsed_time, prep_time)
      timing = " #{elapsed_time.round(2)}s".green

      if prep_time.present?
        prep_percent = (prep_time / elapsed_time) * 100
        timing + " (#{prep_percent.round}% preparation)".yellow
      else
        timing
      end
    end
  end
end
