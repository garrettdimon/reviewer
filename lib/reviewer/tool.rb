# frozen_string_literal: true

require 'yaml/store'

require_relative 'tool/command'
require_relative 'tool/env'
require_relative 'tool/flags'
require_relative 'tool/settings'
require_relative 'tool/verbosity'

module Reviewer
  # Provides an instance of a specific tool
  class Tool
    SIX_HOURS_IN_SECONDS = 60 * 60 * 6

    attr_reader :settings, :history

    delegate :name,
             :description,
             :tags,
             :key,
             :enabled?,
             :disabled?,
             :max_exit_status,
             :prepare_command?,
             :install_command?,
             :format_command?,
             :install_link?,
             to: :settings

    def initialize(tool)
      @settings = Settings.new(tool)
      @history = load_history
    end

    def to_s
      name
    end

    def to_sym
      key
    end

    def last_prepared_at
      history.fetch(:last_prepared_at, nil)
    end

    def last_prepared_at=(last_prepared_at)
      history.transaction { |s| s[key][:last_prepared_at] == last_prepared_at }
    end

    def stale?
      return false unless prepare_command?

      last_prepared_at.nil? || last_prepared_at < Time.current.utc - SIX_HOURS_IN_SECONDS
    end

    def ==(other)
      settings == other.settings
    end

    def installation_command(verbosity_level = :no_silence)
      return nil unless install_command?

      command_string(:install, verbosity_level: verbosity_level)
    end

    def preparation_command(verbosity_level = :total_silence)
      return nil unless prepare_command?

      command_string(:prepare, verbosity_level: verbosity_level)
    end

    def review_command(verbosity_level = :total_silence, seed: nil)
      command_string(:review, verbosity_level: verbosity_level).gsub('$SEED', seed.to_s)
    end

    def format_command(verbosity_level = :no_silence)
      return nil unless format_command?

      command_string(:format, verbosity_level: verbosity_level)
    end

    private

    def load_history
      Reviewer.history_store.transaction { |s| s[key] || {} }
    end

    def command_string(command_type, verbosity_level: :no_silence)
      Command.new(command_type, tool_settings: settings, verbosity_level: verbosity_level).to_s
    end
  end
end
