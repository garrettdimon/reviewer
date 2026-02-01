# frozen_string_literal: true

require 'date'

require_relative 'tool/file_resolver'
require_relative 'tool/settings'
require_relative 'tool/test_file_mapper'

module Reviewer
  # Provides an instance of a specific tool for accessing its settings and run history
  class Tool
    extend Forwardable
    include Comparable

    # In general, Reviewer tries to save time where it can. In the case of the "prepare" command
    # used by some tools to retrieve data, it only runs it occasionally in order to save time.
    # This is the default window that it uses to determine if the tool's preparation step should be
    # considered stale and needs to be rerun. Frequent enough that it shouldn't get stale, but
    # infrequent enough that it's not cumbersome.
    SIX_HOURS_IN_SECONDS = 60 * 60 * 6

    attr_reader :settings, :history

    def_delegators :@settings,
                   :key,
                   :name,
                   :hash,
                   :description,
                   :tags,
                   :commands,
                   :links,
                   :enabled?,
                   :disabled?,
                   :skip_in_batch?,
                   :max_exit_status,
                   :supports_files?

    # @!method to_sym
    #   Returns the tool's key as a symbol
    #   @return [Symbol] the tool's unique identifier
    alias to_sym key

    # @!method to_s
    #   Returns the tool's name as a string
    #   @return [String] the tool's display name
    alias to_s name

    # Create an instance of a tool
    # @param tool_key [Symbol] the key to the tool from the configuration file
    #
    # @return [Tool] an instance of tool for accessing settings information and facts about the tool
    def initialize(tool_key)
      @settings = Settings.new(tool_key)
    end

    # For determining if the tool should run it's prepration command. It will only be run both if
    # the tool has a preparation command, and the command hasn't been run 6 hours
    #
    # @return [Boolean] true if the tool has a configured `prepare` command that hasn't been run in
    #   the last 6 hours
    def prepare? = preparable? && stale?

    # Determines whether a tool has a specific command type configured
    # @param command_type [Symbol] one of the available command types defined in Command::TYPES
    #
    # @return [Boolean] true if the command type is configured and not blank
    def command?(command_type)
      commands.key?(command_type) && !commands[command_type].nil?
    end

    # Determines if the tool can run a `install` command
    #
    # @return [Boolean] true if there is a non-blank `install` command configured
    def installable? = command?(:install)

    # Returns the install command string for this tool
    #
    # @return [String, nil] the install command or nil if not configured
    def install_command
      commands[:install]
    end

    # Determines if the tool can run a `prepare` command
    #
    # @return [Boolean] true if there is a non-blank `prepare` command configured
    def preparable? = command?(:prepare)

    # Determines if the tool can run a `review` command
    #
    # @return [Boolean] true if there is a non-blank `review` command configured
    def reviewable? = command?(:review)

    # Determines if the tool can run a `format` command
    #
    # @return [Boolean] true if there is a non-blank `format` command configured
    def formattable? = command?(:format)

    # Specifies when the tool last had it's `prepare` command run
    #
    # @return [Time] timestamp of when the `prepare` command was last run
    def last_prepared_at
      date_string = Reviewer.history.get(key, :last_prepared_at)

      date_string == '' || date_string.nil? ? nil : DateTime.parse(date_string).to_time
    end

    # Sets the timestamp for when the tool last ran its `prepare` command
    # @param last_prepared_at [DateTime] the value to record for when the `prepare` command last ran
    #
    # @return [DateTime] timestamp of when the `prepare` command was last run
    def last_prepared_at=(last_prepared_at)
      Reviewer.history.set(key, :last_prepared_at, last_prepared_at.to_s)
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
      Reviewer.history.get(key, command.raw_string) || []
    end

    # Records the execution time for a command to calculate running averages
    # @param command [Command] the command that was run
    # @param time [Float, nil] the execution time in seconds
    #
    # @return [void]
    def record_timing(command, time)
      return if time.nil?

      timing = get_timing(command).take(4) << time.round(2)

      Reviewer.history.set(key, command.raw_string, timing)
    end

    # Determines whether the `prepare` command was run recently enough
    #
    # @return [Boolean] true if a prepare command exists, a timestamp exists, and it was run more
    #   than six hours ago
    def stale?
      return false unless preparable?

      last_prepared_at.nil? || last_prepared_at < Time.now - SIX_HOURS_IN_SECONDS
    end

    # Convenience method for determining if a tool has a configured install link
    #
    # @return [Boolean] true if there is an `install` key under links and the value isn't blank
    def install_link? = links.key?(:install) && !links[:install].nil?

    # Returns the text for the install link if available
    #
    # @return [String, nil] the link if it exists, nil otherwise
    def install_link = install_link? ? links.fetch(:install) : nil

    # Determines if two tools are equal
    # @param other [Tool] the tool to compare to the current instance
    #
    # @return [Boolean] true if the settings match
    def eql?(other)
      settings == other.settings
    end
    alias :== eql?

    # Resolves which files this tool should process
    # @param files [Array<String>] the input files to resolve
    #
    # @return [Array<String>] files after mapping and filtering
    def resolve_files(files)
      file_resolver.resolve(files)
    end

    # Determines if this tool should be skipped because files were requested but none match
    # @param files [Array<String>] the requested files
    #
    # @return [Boolean] true if files were requested but none match after resolution
    def skip_files?(files)
      file_resolver.skip?(files)
    end

    private

    def file_resolver
      @file_resolver ||= FileResolver.new(settings)
    end
  end
end
