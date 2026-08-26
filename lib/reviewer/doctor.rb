# frozen_string_literal: true

require_relative 'doctor/formatter'
require_relative 'doctor/report'
require_relative 'doctor/config_check'
require_relative 'doctor/keyword_check'
require_relative 'doctor/tool_inventory'
require_relative 'doctor/discovery_check'
require_relative 'doctor/environment_check'

module Reviewer
  # Diagnostic module for checking configuration, tools, and environment health
  module Doctor
    # Runs all diagnostic checks and returns a structured report
    # @param project_dir [Pathname] the project root to scan
    #
    # @return [Doctor::Report] the complete diagnostic report
    def self.run(configuration:, tools:, project_dir: Pathname.pwd)
      report = Report.new
      configuration_state = ConfigCheck.new(report, configuration: configuration).check

      if configuration_state == :valid
        KeywordCheck.new(report, configuration: configuration, tools: tools).check
        ToolInventory.new(report, configuration: configuration, tools: tools).check
      end

      DiscoveryCheck.new(
        report,
        project_dir,
        configured_keys: report.configured_tools.map(&:key)
      ).check
      EnvironmentCheck.new(report).check
      report
    end
  end
end
