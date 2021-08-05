# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class BatchTest < MiniTest::Test
    def setup
      @result = nil
    end

    def test_running_single_batch
      tools = [Tool.new(:list)]

      capture_subprocess_io do
        @result = Batch.run(:review, tools)
      end

      expected_result = { list: 0 }
      assert_equal expected_result, @result
    end

    def test_running_multiple_batch
      tools = [Tool.new(:list), Tool.new(:minimum_viable_tool)]

      capture_subprocess_io do
        @result = Batch.run(:review, tools)
      end

      expected_result = { list: 0, minimum_viable_tool: 0 }
      assert_equal expected_result, @result
    end
  end
end
