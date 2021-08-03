# frozen_string_literal: true

require_relative 'tool/settings'

module Reviewer
  # Provides an instance of a specific tool for accessing its settings and run history
  class Tool
    include Comparable

    # In general, Reviewer tries to save time where it can. In the case of the "prepare" command
    # used by some tools to retrieve data, it only runs it occasionally in order to save time.
    # This is the default window that it uses to determine if the tool's preparation step should be
    # considered stale and needs to be rerun. Frequent enough that it shouldn't get stale, but
    # infrequent enough that it's not cumbersome.
    SIX_HOURS_IN_SECONDS = 60 * 60 * 6

    attr_reader :settings, :history

    delegate :key,
             :name,
             :hash,
             :description,
             :tags,
             :commands,
             :links,
             :enabled?,
             :disabled?,
             :max_exit_status,
             to: :settings

    alias to_sym key
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
    def prepare?
      preparable? && stale?
    end

    # Determines whether a tool has a specific command type configured
    # @param command_type [Symbol] one of the available command types defined in Command::TYPES
    #
    # @return [Boolean] true if the command type is configured and not blank
    def command?(command_type)
      commands.key?(command_type) && commands[command_type].present?
    end

    # Determines if the tool can run a `install` command
    #
    # @return [Boolean] true if there is a non-blank `install` command configured
    def installable?
      command?(:install)
    end

    # Determines if the tool can run a `prepare` command
    #
    # @return [Boolean] true if there is a non-blank `prepare` command configured
    def preparable?
      command?(:prepare)
    end

    # Determines if the tool can run a `review` command
    #
    # @return [Boolean] true if there is a non-blank `review` command configured
    def reviewable?
      command?(:review)
    end

    # Determines if the tool can run a `format` command
    #
    # @return [Boolean] true if there is a non-blank `format` command configured
    def formattable?
      command?(:format)
    end

    # Specifies when the tool last had it's `prepare` command run
    #
    # @return [DateTime] timestamp of when the `prepare` command was last run
    def last_prepared_at
      Reviewer.history.get(key, :last_prepared_at)
    end

    # Sets the timestamp for when the tool last ran its `prepare` command
    # @param last_prepared_at [DateTime] the value to record for when the `prepare` command last ran
    #
    # @return [DateTime] timestamp of when the `prepare` command was last run
    def last_prepared_at=(last_prepared_at)
      Reviewer.history.set(key, :last_prepared_at, last_prepared_at)
    end

    # Determines whether the `prepare` command was run recently enough
    #
    # @return [Boolean] true if a prepare command exists, a timestamp exists, and it was run more
    #   than six hours ago
    def stale?
      return false unless preparable?

      last_prepared_at.nil? || last_prepared_at < Time.current.utc - SIX_HOURS_IN_SECONDS
    end

    # Convenience method for determining if a tool has a configured install link
    #
    # @return [Boolean] true if there is an `install` key under links and the value isn't blank
    def install_link?
      links.key?(:install) && links[:install].present?
    end

    # Returns the text for the install link if available
    #
    # @return [String, nil] the link if it exists, nil otherwise
    def install_link
      install_link? ? links.fetch(:install) : nil
    end

    # Determines if two tools are equal
    # @param other [Tool] the tool to compare to the current instance
    #
    # @return [Boolean] true if the settings match
    def eql?(other)
      settings == other.settings
    end
    alias :== eql?
  end
end
