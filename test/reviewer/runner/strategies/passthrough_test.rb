# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    module Strategies
      class PassthroughTest < Minitest::Test
        def setup
          @strategy = Runner::Strategies::Passthrough
        end

        def test_passthrough_runner_implementation
          passthrough_runner = Runner.new(:list, :review, @strategy)
          result = nil
          capture_subprocess_io { result = passthrough_runner.run }
          assert_equal 0, result
          assert passthrough_runner.success?
        end

        def test_passthrough_runner_implementation_with_prep
          History.reset!
          passthrough_runner = Runner.new(:list, :review, @strategy)
          result = nil
          capture_subprocess_io { result = passthrough_runner.run }
          assert_equal 0, result
          assert passthrough_runner.success?
        end
      end
    end
  end
end
