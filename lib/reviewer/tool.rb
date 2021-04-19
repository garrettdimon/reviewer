# frozen_string_literal: true

require_relative "tool/command"
require_relative "tool/env"
require_relative "tool/flags"
require_relative "tool/settings"
require_relative "tool/verbosity"

# Provides an instance of a specific tool
module Reviewer
  class Tool
    attr_reader :settings

    delegate :name,
             :description,
             :enabled?,
             :disabled?,
             :max_exit_status,
             :has_prepare_command?,
             :has_install_command?,
             :has_install_link?,
             to: :settings

    def initialize(tool)
      @settings = Settings.new(tool)
    end

    def to_s
      name
    end

    def installation_command(verbosity_level = :no_silence)
      command_string(:install, verbosity_level: verbosity_level)
    end

    def preparation_command(verbosity_level = :total_silence)
       command_string(:prepare, verbosity_level: verbosity_level)
    end

    def review_command(verbosity_level = :total_silence)
      command_string(:review, verbosity_level: verbosity_level)
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
