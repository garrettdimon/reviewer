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

    def test_preserves_review_history_for_tools_that_did_not_run
      @history.set(:minimum_viable_tool, :last_status, :failed)
      @history.set(:minimum_viable_tool, :last_failed_files, ['lib/reviewer/batch.rb'])

      tools = [build_tool(:failing_command), build_tool(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :failed, @history.get(:failing_command, :last_status)
      assert_equal :failed, @history.get(:minimum_viable_tool, :last_status)
      assert_equal ['lib/reviewer/batch.rb'],
                   @history.get(:minimum_viable_tool, :last_failed_files)
    ensure
      @history.set(:minimum_viable_tool, :last_status, nil)
      @history.set(:minimum_viable_tool, :last_failed_files, nil)
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

    def test_records_review_history_for_passing_tool
      @history.set(:list, :last_status, :failed)
      @history.set(:list, :last_failed_files, ['lib/reviewer/batch.rb'])

      tools = [build_tool(:list)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :passed, @history.get(:list, :last_status)
      assert_nil @history.get(:list, :last_failed_files)
    ensure
      @history.set(:list, :last_status, nil)
      @history.set(:list, :last_failed_files, nil)
    end

    def test_preserves_review_history_for_skipped_tools
      @history.set(:file_pattern_tool, :last_status, :failed)
      @history.set(:file_pattern_tool, :last_failed_files, ['lib/reviewer/batch.rb'])
      arguments = Arguments.new(%w[-f README.md])
      context = default_context(arguments: arguments, history: @history)
      tool = build_tool(:file_pattern_tool)

      capture_subprocess_io do
        Batch.new(:review, [tool], strategy: Runner::Strategies::Captured, context: context).run
      end

      assert_equal :failed, @history.get(:file_pattern_tool, :last_status)
      assert_equal ['lib/reviewer/batch.rb'],
                   @history.get(:file_pattern_tool, :last_failed_files)
    ensure
      @history.set(:file_pattern_tool, :last_status, nil)
      @history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_preserves_review_history_for_format_commands
      @history.set(:list, :last_status, :failed)
      @history.set(:list, :last_failed_files, ['lib/reviewer/batch.rb'])

      capture_subprocess_io do
        Batch.new(
          :format,
          [build_tool(:list)],
          strategy: Runner::Strategies::Captured,
          context: @context
        ).run
      end

      assert_equal :failed, @history.get(:list, :last_status)
      assert_equal ['lib/reviewer/batch.rb'], @history.get(:list, :last_failed_files)
    ensure
      @history.set(:list, :last_status, nil)
      @history.set(:list, :last_failed_files, nil)
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

    def test_preserves_review_history_for_missing_tools
      @history.set(:missing_command, :last_status, :failed)
      @history.set(:missing_command, :last_failed_files, ['lib/reviewer/batch.rb'])
      tools = [build_tool(:missing_command)]

      capture_subprocess_io do
        Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal :failed, @history.get(:missing_command, :last_status)
      assert_equal ['lib/reviewer/batch.rb'], @history.get(:missing_command, :last_failed_files)
    ensure
      @history.set(:missing_command, :last_status, nil)
      @history.set(:missing_command, :last_failed_files, nil)
    end

    def test_missing_tool_followed_by_passing_tool
      tools = [build_tool(:missing_command), build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: default_context).run
      end

      assert @report.results.first.missing
      assert @report.results.last.success
    end

    def test_skipped_tool_followed_by_passing_tool
      arguments = Arguments.new(%w[-f README.md])
      context = default_context(arguments: arguments)
      tools = [build_tool(:file_pattern_tool), build_tool(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: context).run
      end

      assert_equal %i[file_pattern_tool list], @report.results.map(&:tool_key)
      assert_equal %i[skipped passed], @report.results.map(&:state)
    end

    def test_reports_each_tool_stopped_after_a_failure # rubocop:disable Metrics/AbcSize
      tools = %i[failing_command minimum_viable_tool list].map { |key| build_tool(key) }

      capture_subprocess_io do
        @report = Batch.new(:review, tools, strategy: Runner::Strategies::Captured, context: @context).run
      end

      assert_equal %i[failing_command minimum_viable_tool list], @report.results.map(&:tool_key)
      assert_equal %i[failed not_run not_run], @report.results.map(&:state)
      unavailable = @report.results.drop(1).map do |result|
        [result.executed?, result.command_string, result.exit_status, result.duration, result.stdout, result.stderr]
      end
      assert_equal [[false, nil, nil, nil, nil, nil], [false, nil, nil, nil, nil, nil]], unavailable
    end
  end
end
