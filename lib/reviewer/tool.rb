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

    delegate :name,
             :description,
             :tags,
             :commands,
             :key,
             :enabled?,
             :disabled?,
             :max_exit_status,
             :install_link?,
             to: :settings

    def initialize(tool)
      @settings = Settings.new(tool)
    end

    def hash
      settings.hash
    end

    def to_s
      name
    end

    def to_sym
      key
    end

    # For determining if the tool should run it's prepration command. It will only be run both if
    # the tool has a preparation command, and the command hasn't been run 6 hours
    #
    # @return [Boolean] true if the tool has a configured `prepare` command that hasn't been run in
    #   the last 6 hours
    def prepare?
      preparable? && stale?
    end

    # Convenience method for knowing if a tool has a specific command type configured.
    # @param command_type [Symbol] one of the available command types defined in Command::TYPES
    #
    # @return [Boolean] true if the command type is configured and not blank
    def has_command?(command_type)
      commands.key?(command_type) && commands[command_type].present?
    end

    def installable?
      has_command?(:install)
    end

    def preparable?
      has_command?(:prepare)
    end

    def reviewable?
      has_command?(:review)
    end

    def formattable?
      has_command?(:format)
    end

    def last_prepared_at
      Reviewer.history.get(key, :last_prepared_at)
    end

    def last_prepared_at=(last_prepared_at)
      Reviewer.history.set(key, :last_prepared_at, last_prepared_at)
    end

    def stale?
      return false unless preparable?

      last_prepared_at.nil? || last_prepared_at < Time.current.utc - SIX_HOURS_IN_SECONDS
    end

    def eql?(other)
      settings == other.settings
    end
    alias :== eql?
  end
end
