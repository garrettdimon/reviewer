# frozen_string_literal: true

require 'colorize'

module Reviewer
  # Friendly API for printing runner-based output to the console
  class Output
    SUCCESS = 'Success'
    FAILURE = 'Failure ·'
    DIVIDER = ('-' * 60).to_s

    attr_reader :logger

    def initialize(logger: Reviewer.logger)
      @logger = logger
    end

    def blank_line
      logger.info
    end

    def divider
      blank_line
      logger.info DIVIDER.light_black
      blank_line
    end

    def tool_summary(tool)
      logger.info "\n#{tool.name}".bold + ' · '.light_black + tool.description
    end

    def current_command(command)
      logger.info "\nNow running:"
      logger.info command.light_black
    end

    def last_command(command)
      logger.info "\nReviewer ran:"
      logger.info command.to_s.light_black
    end

    def raw_results(command)
      current_command(command)
      results_block { system(command) }
      last_command(command)
    end

    def results_block(&block)
      divider
      logger.info(&block)
      divider
    end

    def exit_status(value)
      failure("Exit Status #{value}")
    end

    def success(timer)
      message = SUCCESS.green.bold + " #{timer.elapsed_seconds}s".green
      message += " (#{timer.prep_percent}% preparation)".yellow if timer.prep?

      logger.info message
    end

    def failure(details)
      logger.error "#{FAILURE} #{details}".red.bold
    end

    def unrecoverable(details)
      logger.error 'An Uncrecoverable Error Occured'.red.bold
      logger.error details
    end

    def guidance(summary, details)
      return unless details.present?

      blank_line
      logger.info summary
      logger.info details.to_s.light_black
    end

    def missing_executable_guidance(tool:, command:)
      installation_command = tool.installation_command
      install_link = tool.settings.links&.fetch(:install, nil)

      failure("Missing executable for '#{tool}'")
      last_command(command)
      guidance('Try installing the tool:', installation_command)
      guidance('Read the installation guidance:', install_link)
    end

    def syntax_guidance(ignore_link: nil, disable_link: nil)
      guidance('Selectively Ignore a Rule:', ignore_link)
      guidance('Fully Disable a Rule:', disable_link)
    end
  end
end
