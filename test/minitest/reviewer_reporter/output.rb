# frozen_string_literal: true

module Minitest
  class ReviewerReporter
    # Friendly API for printing nicely-formatted output to the console
    class Output < ::Reviewer::Output
      # Creates an instance of Output to print Reviewer activity and results to the console
      # @param printer: Reviewer.configuration.printer [Reviewer::Printer] a logger designed to write
      #   formatted output to the console based on the results of Reviewer commands
      #
      # @return [self]
      def initialize(printer: ::Reviewer::Printer.new)
        @printer = printer
      end

      def print(value)
        printer << value
      end

      def puts(value = '')
        printer << "#{value}\n"
      end

      def marker(value)
        case value
        when 'E' then text(:red, :bold) { value }
        when 'F' then text(:red) { value }
        when 'S' then text(:yellow) { value }
        else text(:green) { value }
        end
      end

      def compact_summary(errors, failures, skips)
         text(:red, :bold) { pluralize(errors, 'error') } if errors.positive?
         text(:red)        { pluralize(failures, 'failure') } if failures.positive?
         text(:yellow)     { pluralize(errors, 'skip') } if skips.positive?
      end

      def error(result)
      end

      def failure(result)
      end

      def success(result)
      end

      def path(value)
        # Output a path with the repeated parts in a muted color
      end

      def locations_heat_map
      end

      def classes_heat_map
      end

      private

      def pluralize(count, singular)
        results = "#{count} #{singular}"
        results += 's' if count > 1
      end
    end
  end
end
