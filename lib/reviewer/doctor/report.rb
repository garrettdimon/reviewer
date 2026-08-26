# frozen_string_literal: true

module Reviewer
  module Doctor
    # Structured container for diagnostic findings organized by section
    class Report
      # A single diagnostic finding with status, message, and optional detail.
      # @!attribute status [rw]
      #   @return [Symbol] the severity (:ok, :warning, :error, or :info)
      # @!attribute message [rw]
      #   @return [String] the finding summary
      # @!attribute detail [rw]
      #   @return [String, nil] optional detail or guidance text
      Finding = Struct.new(:status, :message, :detail, keyword_init: true) do
        def to_h = { status: status, message: message, detail: detail }.compact
      end

      Observation = Struct.new(:kind, :value, :path, :location, keyword_init: true) do
        def to_h
          source = { path: path }
          source[:location] = location if location
          { kind: kind, value: value, source: source }.compact
        end
      end

      Discovery = Struct.new(:key, :name, :observations, keyword_init: true) do
        def to_h = { key: key, name: name, observations: observations.map(&:to_h) }
      end

      ConfiguredTool = Struct.new(
        :key, :name, :skip_in_batch, :commands, :files, :source,
        keyword_init: true
      ) do
        def to_h
          value = {
            key: key,
            name: name,
            skip_in_batch: skip_in_batch,
            commands: commands,
            source: source
          }
          value[:files] = files unless files.empty?
          value
        end
      end

      Environment = Struct.new(:name, :status, :value, :detail, keyword_init: true) do
        def to_h = { name: name, status: status, value: value, detail: detail }.compact
      end

      # Ordered list of report sections
      SECTIONS = %i[configuration configured_tools discoveries environment].freeze

      attr_reader :findings, :configured_tools, :discoveries, :environment,
                  :configuration_path, :configuration_state

      def initialize
        @findings = Hash.new { |hash, key| hash[key] = [] }
        @configured_tools = []
        @discoveries = []
        @environment = []
        @configuration_state = :unknown
      end

      # Adds a finding to a section
      # @param section [Symbol] one of SECTIONS
      # @param status [Symbol] :ok, :warning, :error, or :info
      # @param message [String] the finding summary
      # @param detail [String, nil] optional detail text
      def add(section, status:, message:, detail: nil)
        findings[section] << Finding.new(status: status, message: message, detail: detail)
      end

      # Whether all findings are free of errors
      def ok?
        all_findings.none? { |finding| finding.status == :error }
      end

      # All error findings across sections
      def errors
        all_findings.select { |finding| finding.status == :error }
      end

      # All warning findings across sections
      def warnings
        all_findings.select { |finding| finding.status == :warning }
      end

      # Findings for a specific section
      # @param name [Symbol] the section name
      # @return [Array<Finding>] findings for that section
      def section(name)
        return configured_tools if name == :configured_tools
        return discoveries if name == :discoveries
        return environment if name == :environment

        findings[name]
      end

      def set_configuration(path:, state:)
        @configuration_path = path
        @configuration_state = state
      end

      def add_configured_tool(key:, name:, skip_in_batch:, commands:, files:, source:)
        configured_tools << ConfiguredTool.new(
          key: key,
          name: name,
          skip_in_batch: skip_in_batch,
          commands: commands,
          files: files,
          source: source
        )
      end

      def add_discovery(key:, name:, observations:)
        discoveries << Discovery.new(key: key, name: name, observations: observations)
      end

      def add_environment(name:, status:, value:, detail: nil)
        environment << Environment.new(name: name, status: status, value: value, detail: detail)
      end

      def to_h
        {
          schema_version: 1,
          configuration: {
            path: configuration_path,
            state: configuration_state,
            findings: section(:configuration).map(&:to_h)
          },
          configured_tools: configured_tools.map(&:to_h),
          discoveries: discoveries.map(&:to_h),
          environment: environment.map(&:to_h),
          summary: summary
        }
      end

      private

      def all_findings
        findings.values.flatten + environment
      end

      def summary
        {
          configured_tools: configured_tools.size,
          discoveries: discoveries.size,
          configuration_issues: section(:configuration).count { |finding| finding.status != :ok },
          environment_warnings: environment.count { |finding| finding.status == :warning }
        }
      end
    end
  end
end
