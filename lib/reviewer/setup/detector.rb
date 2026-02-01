# frozen_string_literal: true

module Reviewer
  module Setup
    # Scans a project directory to detect which review tools are applicable
    # based on Gemfile.lock contents, config files, and directory structure.
    class Detector
      # Value object for a single detection result
      # Value object for a single detection result
      Result = Struct.new(:key, :reasons, keyword_init: true) do
        # @return [String] human-readable tool name from the catalog, or the key as fallback
        def name = Catalog.config_for(key)&.dig(:name) || key.to_s
        # @return [String] formatted line for display (name + reasons)
        def summary = "  #{name.ljust(22)}#{reasons.join(', ')}"
      end

      attr_reader :project_dir

      # @param project_dir [Pathname, String] the project root to scan
      def initialize(project_dir = Pathname.pwd)
        @project_dir = Pathname(project_dir)
      end

      # Scans the project and returns detection results for matching tools
      #
      # @return [Array<Result>] detected tools with evidence
      def detect
        gems = GemfileLock.new(project_dir.join('Gemfile.lock')).gem_names

        Catalog.all.filter_map do |key, definition|
          reasons = reasons_for(definition[:detect], gems)
          Result.new(key: key, reasons: reasons) if reasons.any?
        end
      end

      private

      def reasons_for(detect, gems)
        gem_reasons(detect, gems) + file_reasons(detect) + directory_reasons(detect)
      end

      def gem_reasons(detect, gems)
        Array(detect[:gems]).select { |name| gems.include?(name) }.map { |name| "#{name} in Gemfile.lock" }
      end

      def file_reasons(detect)
        Array(detect[:files]).select { |name| project_dir.join(name).exist? }
      end

      def directory_reasons(detect)
        Array(detect[:directories]).select { |name| project_dir.join(name).directory? }.map { |name| "#{name}/ directory" }
      end
    end
  end
end
