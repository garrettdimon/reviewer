# frozen_string_literal: true

require 'benchmark'
require 'colorize'
require 'open3'

# Handles running, benchmarking, and printing output for a command
module Reviewer
  class Runner
    SUCCESS = "Success".freeze
    FAILURE = "Failure ·".freeze
    PROMPT  = "$"

    attr_accessor :tool, :command

    attr_reader :elapsed_time, :stdout, :stderr, :status, :exception, :exit_status

    def initialize(tool, command, logger: nil)
      @tool = tool
      @command = command
      @logger = logger
    end

    def run
      print_tool_info

      @elapsed_time = Benchmark.realtime do
        prepare
        review
      end

      print_result
    rescue => e
      @exception = e
      print_exception
    ensure
      return [exit_status, elapsed_time]
    end


    private

    def shell_out(cmd)
      @stdout, @stderr, @status = Open3.capture3(cmd)
      @exit_status = status.exitstatus

      puts "#{PROMPT} #{cmd}".light_black unless status.success?
    end

    def prepare
      return unless tool.has_prepare_command?

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
      puts "\n#{tool.name}".bold + " · ".light_black + tool.description
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
        if tool.has_install_command?
          puts "  Installation Command:\n"
          puts "  #{tool.installation_command}\n".light_black
        end
        if tool.has_install_link?
          puts "  Installation Help:"
          puts "  #{tool.settings.links[:install]}\n".light_black
        end
      else
        # puts "#{stderr}".red
        review_verbosely
      end
    end

    def print_exception
      puts "\n\n"
      puts "#{exception.message}".red.bold
      puts exception.backtrace.join("\n")
    end

    def missing_executable?
      stderr.include?("can't find executable")
    end
  end
end
