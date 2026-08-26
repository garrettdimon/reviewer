# frozen_string_literal: true

module Reviewer
  module Setup
    # Scans a project directory to detect which review tools are applicable
    # based on Gemfile.lock contents, config files, and directory structure.
    class Detector
      Source = Struct.new(:kind, :path, :location, keyword_init: true) do
        def description
          case kind
          when :dependency then "#{location} in #{path}"
          when :directory then "#{path}/ directory"
          else path
          end
        end

        def to_h
          source = { path: path }
          source[:location] = location if location
          { kind: kind, source: source }
        end
      end

      # Value object for a single detection result (tool key + evidence).
      # @!attribute key [rw]
      #   @return [Symbol] the tool identifier from the catalog
      # @!attribute reasons [rw]
      #   @return [Array<String>] evidence strings explaining why the tool was detected
      Result = Struct.new(:key, :sources, keyword_init: true) do
        # @return [String] human-readable tool name from the catalog, or the key as fallback
        def name = Catalog.config_for(key)&.dig(:name) || key.to_s
        def reasons = sources.map(&:description)
        # @return [String] formatted line for display (name + reasons)
        def summary = "  #{name.ljust(22)}#{reasons.join(', ')}"
      end

      attr_reader :project_dir

      # Creates a detector for scanning a project directory for supported tools
      # @param project_dir [Pathname, String] the project root to scan
      #
      # @return [Detector]
      def initialize(project_dir = Pathname.pwd)
        @project_dir = Pathname(project_dir)
      end

      # Scans the project and returns detection results for matching tools
      #
      # @return [Array<Result>] detected tools with evidence
      def detect
        gems = GemfileLock.new(project_dir.join('Gemfile.lock')).gem_names

        Catalog.all.filter_map do |key, definition|
          sources = sources_for(definition[:detect], gems)
          Result.new(key: key, sources: sources) if sources.any?
        end
      end

      private

      def sources_for(detect, gems)
        gem_sources(detect, gems) + file_sources(detect) + directory_sources(detect)
      end

      def gem_sources(detect, gems)
        Array(detect[:gems]).select { |name| gems.include?(name) }.map do |name|
          Source.new(kind: :dependency, path: 'Gemfile.lock', location: name)
        end
      end

      def file_sources(detect)
        Array(detect[:files]).select { |name| project_dir.join(name).exist? }.map do |name|
          Source.new(kind: :configuration_file, path: name)
        end
      end

      def directory_sources(detect)
        Array(detect[:directories]).select { |name| project_dir.join(name).directory? }.map do |name|
          Source.new(kind: :directory, path: name)
        end
      end
    end
  end
end
