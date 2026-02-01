# frozen_string_literal: true

module Reviewer
  module Setup
    # Parses a Gemfile.lock to extract gem names from the specs section
    class GemfileLock
      # Spec lines are indented with 4 spaces: "    gem-name (version)"
      SPEC_LINE = /\A {4}(\S+)\s/

      attr_reader :path

      # @param path [Pathname] the path to the Gemfile.lock file
      def initialize(path)
        @path = path
      end

      # Returns the set of gem names found in the specs section
      #
      # @return [Set<String>] gem names
      def gem_names
        return Set.new unless path.exist?

        parse_specs
      end

      private

      def parse_specs
        in_specs = false
        gems = Set.new

        path.each_line do |line|
          in_specs, gem_name = process_line(line, in_specs)
          gems.add(gem_name) if gem_name
        end

        gems
      end

      def process_line(line, in_specs)
        return [true, nil] if line.strip == 'specs:'
        return [in_specs, nil] unless in_specs

        match = line.match(SPEC_LINE)
        return [true, match[1]] if match

        still_in_specs = line.start_with?('      ') || line.strip.empty?
        [still_in_specs, nil]
      end
    end
  end
end
