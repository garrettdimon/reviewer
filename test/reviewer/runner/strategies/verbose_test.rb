# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    module Strategies
      class VerboseTest < MiniTest::Test
        def test_verbose_runner_implementation
          verbose_runner = Runner.new(:list, :review, Runner::Strategies::Verbose)
          capture_subprocess_io { verbose_runner.run }
          assert verbose_runner.success?
        end

        def test_verbose_runner_implementation_with_prep
          History.reset!
          verbose_runner = Runner.new(:list, :review, Runner::Strategies::Verbose)
          capture_subprocess_io { verbose_runner.run }
          assert verbose_runner.success?
        end
      end
    end
  end
end
