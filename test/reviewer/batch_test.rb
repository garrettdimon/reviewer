# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class BatchTest < Minitest::Test
    def setup
      @report = nil
      @history = Reviewer.history
      @context = default_context(history: @history)
    end

    def test_running_single_batch
      tools = [build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert_instance_of Report, @report
      assert_equal 1, @report.results.size
      assert @report.success?
      assert_equal :list, @report.results.first.tool_key
    end

    def test_running_multiple_batch
      tools = [build_tool(:list), build_tool(:minimum_viable_tool)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert_instance_of Report, @report
      assert_equal 2, @report.results.size
      assert @report.success?
      assert_equal %i[list minimum_viable_tool], @report.results.map(&:tool_key)
    end

    def test_records_duration
      tools = [build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert_kind_of Float, @report.duration
      assert @report.duration >= 0
    end

    def test_records_passed_status_in_history
      tools = [build_tool(:list), build_tool(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :passed, @history.get(:list, :last_status)
      assert_equal :passed, @history.get(:minimum_viable_tool, :last_status)
    end

    def test_records_failed_status_in_history
      tools = [build_tool(:failing_command)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :failed, @history.get(:failing_command, :last_status)
    end

    def test_clears_status_for_tools_that_did_not_run
      @history.set(:minimum_viable_tool, :last_status, :failed)

      tools = [build_tool(:failing_command), build_tool(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :failed, @history.get(:failing_command, :last_status)
      assert_nil @history.get(:minimum_viable_tool, :last_status)
    end

    def test_stores_failed_files_on_failure
      tools = [build_tool(:failing_with_output), build_tool(:list)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      failed_files = @history.get(:failing_with_output, :last_failed_files)
      assert_includes failed_files, 'lib/reviewer/batch.rb'
      assert_includes failed_files, 'lib/reviewer/command.rb'
    end

    def test_stores_failed_files_on_single_tool_failure
      tools = [build_tool(:failing_with_output)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      failed_files = @history.get(:failing_with_output, :last_failed_files)
      assert_includes failed_files, 'lib/reviewer/batch.rb'
      assert_includes failed_files, 'lib/reviewer/command.rb'
    end

    def test_clears_failed_files_for_passing_tool
      @history.set(:list, :last_failed_files, ['lib/reviewer/batch.rb'])

      tools = [build_tool(:list)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_nil @history.get(:list, :last_failed_files)
    end

    def test_preserves_failed_files_for_tools_that_did_not_run
      @history.set(:minimum_viable_tool, :last_failed_files, ['lib/reviewer/batch.rb'])

      tools = [build_tool(:failing_command), build_tool(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal ['lib/reviewer/batch.rb'],
                   @history.get(:minimum_viable_tool, :last_failed_files)
    end

    def test_command_includes_stored_failed_files
      @history.set(:file_targeting_list, :last_failed_files, ['lib/reviewer/batch.rb'])
      @history.set(:file_targeting_list, :last_status, :failed)

      arguments = Arguments.new(%w[failed])
      context = Context.new(arguments: arguments, output: Output.new, history: @history)
      tools = [build_tool(:file_targeting_list)]
      report = nil

      capture_subprocess_io do
        report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: context).run
      end

      command_string = report.results.first.command_string
      assert_includes command_string, 'lib/reviewer/batch.rb'
    end

    def test_uses_injected_strategy
      tools = [build_tool(:list)]
      batch = Batch.new(:review, tools, strategy: Runner::Strategies::Passthrough, context: default_context)

      assert_equal Runner::Strategies::Passthrough, batch.send(:strategy)
    end

    def test_continues_past_missing_tools
      tools = [build_tool(:missing_command), build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert_equal 2, @report.results.size
      assert_equal %i[missing_command list], @report.results.map(&:tool_key)
    end

    def test_does_not_record_run_for_missing_tools
      tools = [build_tool(:missing_command)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_nil @history.get(:missing_command, :last_status)
    end

    def test_missing_tool_followed_by_passing_tool
      tools = [build_tool(:missing_command), build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert @report.results.first.missing
      assert @report.results.last.success
    end
  end
end
