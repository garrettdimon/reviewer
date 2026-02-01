# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class BatchTest < Minitest::Test
    def setup
      @report = nil
      @history = Reviewer.history
    end

    def test_running_single_batch
      tools = [Tool.new(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools).run
      end

      assert_instance_of Report, @report
      assert_equal 1, @report.results.size
      assert @report.success?
      assert_equal :list, @report.results.first.tool_key
    end

    def test_running_multiple_batch
      tools = [Tool.new(:list), Tool.new(:minimum_viable_tool)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools).run
      end

      assert_instance_of Report, @report
      assert_equal 2, @report.results.size
      assert @report.success?
      assert_equal %i[list minimum_viable_tool], @report.results.map(&:tool_key)
    end

    def test_records_duration
      tools = [Tool.new(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools).run
      end

      assert_kind_of Float, @report.duration
      assert @report.duration >= 0
    end

    def test_records_passed_status_in_history
      tools = [Tool.new(:list), Tool.new(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      assert_equal :passed, @history.get(:list, :last_status)
      assert_equal :passed, @history.get(:minimum_viable_tool, :last_status)
    end

    def test_records_failed_status_in_history
      tools = [Tool.new(:failing_command)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      assert_equal :failed, @history.get(:failing_command, :last_status)
    end

    def test_clears_status_for_tools_that_did_not_run
      # Pre-populate a stale failed status
      @history.set(:minimum_viable_tool, :last_status, :failed)

      # Run a batch where the first tool fails, so minimum_viable_tool never runs
      tools = [Tool.new(:failing_command), Tool.new(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      assert_equal :failed, @history.get(:failing_command, :last_status)
      assert_nil @history.get(:minimum_viable_tool, :last_status)
    end

    def test_stores_failed_files_on_failure
      # Two tools so Captured strategy is used
      tools = [Tool.new(:failing_with_output), Tool.new(:list)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      failed_files = @history.get(:failing_with_output, :last_failed_files)
      assert_includes failed_files, 'lib/reviewer/batch.rb'
      assert_includes failed_files, 'lib/reviewer/command.rb'
    end

    def test_stores_failed_files_on_single_tool_failure
      # Single tool uses Passthrough strategy — PTY capture enables file extraction
      tools = [Tool.new(:failing_with_output)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      failed_files = @history.get(:failing_with_output, :last_failed_files)
      assert_includes failed_files, 'lib/reviewer/batch.rb'
      assert_includes failed_files, 'lib/reviewer/command.rb'
    end

    def test_clears_failed_files_for_passing_tool
      # Pre-populate stale failed files
      @history.set(:list, :last_failed_files, ['lib/reviewer/batch.rb'])

      tools = [Tool.new(:list)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      assert_nil @history.get(:list, :last_failed_files)
    end

    def test_preserves_failed_files_for_tools_that_did_not_run
      # Pre-populate stale failed files
      @history.set(:minimum_viable_tool, :last_failed_files, ['lib/reviewer/batch.rb'])

      # First tool fails, so minimum_viable_tool never runs
      tools = [Tool.new(:failing_command), Tool.new(:minimum_viable_tool)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      # Failed files persist until the tool actually runs and passes
      assert_equal ['lib/reviewer/batch.rb'],
                   @history.get(:minimum_viable_tool, :last_failed_files)
    end

    def test_command_includes_stored_failed_files
      # Pre-populate failed files for a file-targeting tool
      @history.set(:file_targeting_list, :last_failed_files, ['lib/reviewer/batch.rb'])
      @history.set(:file_targeting_list, :last_status, :failed)

      arguments = Arguments.new(%w[failed])
      tools = [Tool.new(:file_targeting_list)]
      report = nil

      capture_subprocess_io do
        report = Batch.new(:review, tools, history: @history, arguments: arguments).run
      end

      # The command string should include the stored file
      command_string = report.results.first.command_string
      assert_includes command_string, 'lib/reviewer/batch.rb'
    end

    def test_uses_passthrough_strategy_when_raw_flag_set
      raw_args = Arguments.new(%w[-r])
      tools = [Tool.new(:list), Tool.new(:minimum_viable_tool)]
      batch = Batch.new(:review, tools, arguments: raw_args)

      assert_equal Runner::Strategies::Passthrough, batch.instance_variable_get(:@strategy)
    end

    def test_continues_past_missing_tools
      # missing_command exits 127, list should still run
      tools = [Tool.new(:missing_command), Tool.new(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools).run
      end

      assert_equal 2, @report.results.size
      assert_equal %i[missing_command list], @report.results.map(&:tool_key)
    end

    def test_does_not_record_run_for_missing_tools
      tools = [Tool.new(:missing_command)]

      capture_subprocess_io do
        Batch.new(:review, tools, history: @history).run
      end

      assert_nil @history.get(:missing_command, :last_status)
    end

    def test_missing_tool_followed_by_passing_tool
      tools = [Tool.new(:missing_command), Tool.new(:list)]

      capture_subprocess_io do
        @report = Batch.new(:review, tools).run
      end

      # The missing tool result should be marked missing
      assert @report.results.first.missing

      # The passing tool should succeed
      assert @report.results.last.success
    end
  end
end
