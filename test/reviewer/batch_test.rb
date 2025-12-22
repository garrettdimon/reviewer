# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class BatchTest < Minitest::Test
    def setup
      @report = nil
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

    def test_uses_passthrough_strategy_when_raw_flag_set
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-r]))

      tools = [Tool.new(:list), Tool.new(:minimum_viable_tool)]
      batch = Batch.new(:review, tools)

      assert_equal Runner::Strategies::Passthrough, batch.send(:strategy)
    ensure
      Reviewer.reset!
      ensure_test_configuration!
    end
  end
end
