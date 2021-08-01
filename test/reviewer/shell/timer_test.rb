# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Shell
    class TimerTest < MiniTest::Test
      def test_records_prep_time
        timer = Timer.new
        assert timer.prep.nil?
        timer.record_prep { Benchmark.realtime { true } }
        refute timer.prep.nil?
      end

      def test_records_main_time
        timer = Timer.new
        assert timer.main.nil?
        timer.record_main { Benchmark.realtime { true } }
        refute timer.main.nil?
      end

      def test_exposes_prep_seconds_rounded
        time = 1.23456
        timer = Timer.new(prep: time)
        assert_equal time, timer.prep
        assert_equal time.round(2), timer.prep_seconds
      end

      def test_exposes_main_seconds_rounded
        time = 1.23456
        timer = Timer.new(main: time)
        assert_equal time, timer.main
        assert_equal time.round(2), timer.main_seconds
      end

      def test_exposes_total_seconds_rounded
        time = 1.23456
        total = time + time
        timer = Timer.new(prep: time, main: time)
        assert_equal total, timer.total
        assert_equal total.round(2), timer.total_seconds
      end

      def test_exposes_prep_percent
        timer = Timer.new(prep: 1, main: 1)
        assert_equal 50, timer.prep_percent
      end

      def test_raises_error_on_prep_percent_without_prep
        timer = Timer.new(main: 2)
        assert_nil timer.prep_percent
      end
    end
  end
end
