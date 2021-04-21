# frozen_string_literal: true

require 'colorize'
require 'open3'

module Reviewer
  # Handles running, benchmarking, and printing output for a command
  class Runner
    SUCCESS = 'Success'
    FAILURE = 'Failure ·'
    PROMPT  = '$'

    attr_accessor :tool, :command

    attr_reader :elapsed_time, :stdout, :stderr, :status, :exception, :exit_status

    def initialize(tool, command)
      @tool = tool
      @command = command
    end

    def run
      print_tool_info

      @elapsed_time = Benchmark.realtime do
        prepare
        review
      end

      print_result
      exit_status
    rescue StandardError => e
      @exception = e
      print_exception
      exit_status
    ensure
      @exit_status = nil
    end

    private

    def shell_out(cmd)
      @stdout, @stderr, @status = Open3.capture3(cmd)
      @exit_status = status.exitstatus

      puts "#{PROMPT} #{cmd}".light_black unless status.success?
    end

    def prepare
      return unless tool.prepare_command?

      shell_out(tool.preparation_command)
    end

    def review
      shell_out(tool.review_command)
    end

    def review_verbosely
      cmd = tool.review_command(:no_silence)
      puts "Re-running #{tool.name} verbosely:"
      system(cmd)
    end

    def print_tool_info
      # Outputs the tool name and description.
      puts "\n#{tool.name}".bold + ' · '.light_black + tool.description
    end

    def print_result
      if status.success?
        # Outputs success details
        puts SUCCESS.green.bold + " (#{elapsed_time.round(3)}s)\n".green
      else
        recovery_guidance
      end
    end

    def error_message
      if missing_executable?
        "Missing executable for '#{tool}'"
      else
        "Exit Status #{exit_status}"
      end
    end

    def recovery_guidance
      puts FAILURE.red.bold + " #{error_message}\n".red.bold
      if missing_executable?
        missing_executable_guidance
      else
        review_verbosely
      end
    end

    def missing_executable_guidance
      # TODO: Proactively suggest updating dependency files based on bundler/yarn/etc.
      if tool.install_command?
        puts '  Installation Command:'
        puts "  #{tool.installation_command}\n".light_black
      end

      return unless tool.install_link?

      puts '  Installation Help:'
      puts "  #{tool.settings.links[:install]}\n".light_black
    end

    def print_exception
      puts "\n\n"
      puts exception.message.red.bold
      puts exception.backtrace.join("\n")
    end

    def missing_executable?
      stderr.include?("can't find executable")
    end
  end
end
