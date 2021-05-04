# frozen_string_literal: true

require 'colorize'

module Reviewer
  # Clean formatter for logging to $stdout
  class StandardOutFormatter < ::Logger::Formatter
    def call(_severity, _time, _progname, message)
      "#{message}\n"
    end
  end

  # Logger for $stdout
  class Logger < ::Logger
    SUCCESS = 'Success'
    FAILURE = 'Failure ·'
    PROMPT  = '$'

    def initialize(formatter = StandardOutFormatter.new)
      super($stdout)
      @formatter = formatter
    end

    def running(tool)
      info "\n#{tool.name}".bold + ' · '.light_black + tool.description
    end

    def command(cmd)
      info "#{PROMPT} #{cmd}".light_black
    end

    def rerunning(tool)
      info "\n\nRe-running #{tool.name} verbosely:"
    end

    def success(elapsed_time)
      info SUCCESS.green.bold + " (#{elapsed_time.round(3)}s)".green
    end

    def failure(message)
      info "#{FAILURE} #{message}".red.bold
    end

    def guidance(summary, details)
      info "  #{summary}" if summary
      info "  #{details}".light_black if details
    end
  end
end
