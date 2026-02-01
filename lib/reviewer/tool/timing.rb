# frozen_string_literal: true

require 'date'

module Reviewer
  class Tool
    # Manages timing persistence for a tool — recording, retrieving, and averaging
    # execution times, plus tracking when the prepare command was last run.
    class Timing
      SIX_HOURS_IN_SECONDS = 60 * 60 * 6

      def initialize(history, key)
        @history = history
        @key = key
      end

      # Specifies when the tool last had its `prepare` command run
      #
      # @return [Time, nil] timestamp of when the `prepare` command was last run
      def last_prepared_at
        date_string = @history.get(@key, :last_prepared_at)

        date_string == '' || date_string.nil? ? nil : DateTime.parse(date_string).to_time
      end

      # Sets the timestamp for when the tool last ran its `prepare` command
      # @param timestamp [DateTime, Time] the value to record
      #
      # @return [void]
      def last_prepared_at=(timestamp)
        @history.set(@key, :last_prepared_at, timestamp.to_s)
      end

      # Calculates the average execution time for a command
      # @param command [Command] the command to get timing for
      #
      # @return [Float] the average time in seconds or 0 if no history
      def average_time(command)
        times = get_timing(command)

        times.any? ? times.sum / times.size : 0
      end

      # Retrieves historical timing data for a command
      # @param command [Command] the command to look up
      #
      # @return [Array<Float>] the last few recorded execution times
      def get_timing(command)
        @history.get(@key, command.raw_string) || []
      end

      # Records the execution time for a command to calculate running averages
      # @param command [Command] the command that was run
      # @param time [Float, nil] the execution time in seconds
      #
      # @return [void]
      def record_timing(command, time)
        return if time.nil?

        timing = get_timing(command).take(4) << time.round(2)

        @history.set(@key, command.raw_string, timing)
      end

      # Determines whether the `prepare` command was run recently enough
      #
      # @return [Boolean] true if the timestamp is nil or older than six hours
      def stale?
        last_prepared_at.nil? || last_prepared_at < Time.now - SIX_HOURS_IN_SECONDS
      end
    end
  end
end
