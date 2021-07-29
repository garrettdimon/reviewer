# frozen_string_literal: true

require 'open3'

require_relative 'shell/result'
require_relative 'shell/timer'

module Reviewer
  # Handles running, timing, and capturing results for a command
  class Shell
    class NilCommandError < ArgumentError; end

    attr_accessor :command, :preparation

    attr_reader :timer, :result

    delegate :exit_status, to: :result

    def initialize(command: nil, preparation: nil)
      @command = command
      @preparation = preparation
      @timer = Timer.new
      @result = Result.new
    end

    def run_and_benchmark
      timer.record_elapsed do
        prepare
        perform
      end
    end

    def direct(one_off_command)
      result.exit_status = system(one_off_command) ? 0 : 1
    end

    private

    def run_and_capture_results(command)
      captured_results = Open3.capture3(command)
      @result = Result.new(*captured_results)
    end

    def prepare
      return unless preparation.present?

      timer.record_prep { run_and_capture_results(preparation) }
    end

    def perform
      raise UndefinedCommandError, 'You must specify a command to run' unless command.present?

      run_and_capture_results(command)
    end
  end
end
