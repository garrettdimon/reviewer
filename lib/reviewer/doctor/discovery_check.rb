# frozen_string_literal: true

require 'json'
require 'shellwords'

module Reviewer
  module Doctor
    # Reports known tools observed in the project but absent from valid configuration.
    class DiscoveryCheck
      SHELL_OPERATORS = /[;&|\r\n]/

      def initialize(report, project_dir, configured_keys:)
        @report = report
        @project_dir = Pathname(project_dir)
        @configured_keys = configured_keys.map(&:to_sym)
      end

      def check
        observations = detector_observations
        package_script_observations.each do |key, observation|
          observations[key] << observation
        end

        Setup::Catalog.all.each_key do |key|
          next if @configured_keys.include?(key) || observations[key].empty?

          @report.add_discovery(
            key: key,
            name: Setup::Catalog.config_for(key).fetch(:name),
            observations: observations[key].uniq(&:to_h)
          )
        end
      end

      private

      def detector_observations
        Setup::Detector.new(@project_dir).detect.each_with_object(observation_hash) do |result, found|
          found[result.key].concat(result.sources.map do |source|
            Report::Observation.new(kind: source.kind, path: source.path, location: source.location)
          end)
        end
      end

      def package_script_observations
        package_scripts.filter_map do |script, command|
          key = tool_key_for(command)
          next unless key

          [key, Report::Observation.new(
            kind: :command,
            value: command,
            path: 'package.json',
            location: "scripts.#{script}"
          )]
        end
      end

      def package_scripts
        package = JSON.parse(@project_dir.join('package.json').read)
        scripts = package['scripts'] if package.is_a?(Hash)
        scripts.is_a?(Hash) ? scripts : {}
      rescue Errno::ENOENT, JSON::ParserError
        {}
      end

      def tool_key_for(command)
        return if !command.is_a?(String) || command.match?(SHELL_OPERATORS)

        executable = Shellwords.shellsplit(command).first
        return unless executable

        Setup::Catalog.all.find do |_key, definition|
          Array(definition.dig(:detect, :executables)).include?(executable)
        end&.first
      rescue ArgumentError
        nil
      end

      def observation_hash
        Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end
