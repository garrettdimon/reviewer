# frozen_string_literal: true

require_relative 'tool/file_resolver'
require_relative 'tool/settings'
require_relative 'tool/test_file_mapper'
require_relative 'tool/timing'

module Reviewer
  # Provides an instance of a specific tool for accessing its settings and run history
  class Tool
    extend Forwardable
    include Comparable

    SIX_HOURS_IN_SECONDS = Timing::SIX_HOURS_IN_SECONDS

    attr_reader :settings

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
    # @param history [History] the history store for timing and state persistence
    #
    # @return [Tool] an instance of tool for accessing settings information and facts about the tool
    def initialize(tool_key, history: Reviewer.history)
      @settings = Settings.new(tool_key)
      @history = history
      @timing = Timing.new(history, key)
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

    def_delegators :@timing,
                   :last_prepared_at,
                   :last_prepared_at=,
                   :average_time,
                   :get_timing,
                   :record_timing

    # Determines whether the `prepare` command was run recently enough
    #
    # @return [Boolean] true if a prepare command exists, a timestamp exists, and it was run more
    #   than six hours ago
    def stale?
      return false unless preparable?

      @timing.stale?
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
