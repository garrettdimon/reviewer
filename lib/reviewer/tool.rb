# frozen_string_literal: true

require_relative 'tool/settings'

module Reviewer
  # Provides an instance of a specific tool
  class Tool
    include Comparable

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

    def prepare?
      preparable? && stale?
    end

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

    # def installation_command(verbosity_level = Verbosity::NO_SILENCE)
    #   return nil unless install_command?

    #   command_string(:install, verbosity_level: verbosity_level)
    # end

    # def preparation_command(verbosity_level = Verbosity::TOTAL_SILENCE)
    #   return nil unless prepare_command?

    #   command_string(:prepare, verbosity_level: verbosity_level)
    # end

    # def review_command(verbosity_level = Verbosity::TOTAL_SILENCE, seed: nil)
    #   cmd = command_string(:review, verbosity_level: verbosity_level)

    #   return cmd unless cmd.include?(SEED_SUBSTITUTION_VALUE)

    #   Reviewer.history.set(key, :last_seed, seed)
    #   cmd.gsub(SEED_SUBSTITUTION_VALUE, seed.to_s)
    # end

    # def format_command(verbosity_level = Verbosity::NO_SILENCE)
    #   return nil unless format_command?

    #   command_string(:format, verbosity_level: verbosity_level)
    # end

    # private

    # def command_string(command_type, verbosity_level: Verbosity::NO_SILENCE)
    #   Command::String.new(command_type, tool_settings: settings, verbosity_level: verbosity_level).to_s
    # end
  end
end
