# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class TimerTest < MiniTest::Test
      def test_records_prep_time
        timer = Timer.new
        assert timer.prep.nil?
        timer.record_prep { Benchmark.realtime { true } }
        refute timer.prep.nil?
      end

      def test_records_elapsed_time
        timer = Timer.new
        assert timer.elapsed.nil?
        timer.record_elapsed { Benchmark.realtime { true } }
        refute timer.elapsed.nil?
      end

      def test_exposes_elapsed_seconds_rounded
        time = 1.23456
        timer = Timer.new(elapsed: time)
        assert_equal time, timer.elapsed
        assert_equal time.round(2), timer.elapsed_seconds
      end

      def test_exposes_prep_seconds_rounded
        time = 1.23456
        timer = Timer.new(prep: time)
        assert_equal time, timer.prep
        assert_equal time.round(2), timer.prep_seconds
      end

      def test_exposes_prep_percent
        timer = Timer.new(elapsed: 2)
        assert_equal 0, timer.prep_percent

        timer = Timer.new(elapsed: 2, prep: 1)
        assert_equal 50, timer.prep_percent
      end
    end
  end
end
