# frozen_string_literal: true

module Reviewer
  # Clean formatter for logging to $stdout
  class StandardOutFormatter < ::Logger::Formatter
    # Overrides ::Logger::Formatter `call` to present output more concisely
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
    def initialize(formatter = StandardOutFormatter.new)
      super($stdout)
      @formatter = formatter
    end
  end
end
