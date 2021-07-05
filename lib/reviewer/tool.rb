# frozen_string_literal: true

require_relative 'tool/command'
require_relative 'tool/env'
require_relative 'tool/flags'
require_relative 'tool/settings'
require_relative 'tool/verbosity'

module Reviewer
  # Provides an instance of a specific tool
  class Tool
    attr_reader :settings

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
    end

    def to_s
      name
    end

    def to_sym
      key
    end

    def ==(other)
      settings == other.settings
    end

    def installation_command(verbosity_level = :no_silence)
      command_string(:install, verbosity_level: verbosity_level)
    end

    def preparation_command(verbosity_level = :total_silence)
      command_string(:prepare, verbosity_level: verbosity_level)
    end

    def review_command(verbosity_level = :total_silence, seed: nil)
      command_string(:review, verbosity_level: verbosity_level).gsub('$SEED', seed.to_s)
    end

    def format_command(verbosity_level = :no_silence)
      command_string(:format, verbosity_level: verbosity_level)
    end

    private

    def command_string(command_type, verbosity_level: :no_silence)
      cmd = Command.new(command_type, tool_settings: settings, verbosity_level: verbosity_level)

      cmd.to_s
    end
  end
end
