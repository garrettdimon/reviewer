# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class TimingTest < Minitest::Test
      def setup
        @history = Reviewer.history
        @timing = Timing.new(@history, :enabled_tool)
      end

      def test_last_prepared_at_returns_nil_when_unset
        @history.set(:enabled_tool, :last_prepared_at, nil)
        assert_nil @timing.last_prepared_at
      end

      def test_last_prepared_at_returns_nil_for_empty_string
        @history.set(:enabled_tool, :last_prepared_at, '')
        assert_nil @timing.last_prepared_at
      end

      def test_last_prepared_at_round_trips_through_history
        timestamp = Time.now
        @timing.last_prepared_at = timestamp

        assert_equal timestamp.to_s, @timing.last_prepared_at.to_s
      end

      def test_stale_when_never_prepared
        @timing.last_prepared_at = nil
        assert @timing.stale?
      end

      def test_stale_when_prepared_long_ago
        @timing.last_prepared_at = Time.now - (Timing::SIX_HOURS_IN_SECONDS + 1)
        assert @timing.stale?
      end

      def test_not_stale_when_recently_prepared
        @timing.last_prepared_at = Time.now - (Timing::SIX_HOURS_IN_SECONDS - 1)
        refute @timing.stale?
      end

      def test_get_timing_returns_empty_array_when_unset
        assert_equal [], @timing.get_timing(stub_command('nonexistent'))
      end

      def test_record_timing_stores_and_retrieves
        cmd = stub_command('ls -la')
        @timing.record_timing(cmd, 1.234)

        times = @timing.get_timing(cmd)
        assert_includes times, 1.23
      end

      def test_record_timing_ignores_nil
        cmd = stub_command('ls -la')
        @timing.record_timing(cmd, nil)
        # Should not raise
      end

      def test_record_timing_keeps_last_five
        cmd = stub_command('ls -la')
        6.times { |i| @timing.record_timing(cmd, i.to_f) }

        times = @timing.get_timing(cmd)
        assert_equal 5, times.size
      end

      def test_average_time_calculates_mean
        cmd = stub_command('ls -la')
        @timing.record_timing(cmd, 1.0)
        @timing.record_timing(cmd, 3.0)

        assert_equal 2.0, @timing.average_time(cmd)
      end

      def test_average_time_returns_zero_when_no_history
        assert_equal 0, @timing.average_time(stub_command('nonexistent'))
      end

      private

      def stub_command(raw_string)
        Struct.new(:raw_string).new(raw_string)
      end
    end
  end
end
