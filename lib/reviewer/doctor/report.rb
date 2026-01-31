# frozen_string_literal: true

module Reviewer
  module Doctor
    # Structured container for diagnostic findings organized by section
    class Report
      # A single diagnostic finding with status, message, and optional detail
      Finding = Struct.new(:status, :message, :detail, keyword_init: true)

      # Ordered list of report sections
      SECTIONS = %i[configuration tools opportunities environment].freeze

      attr_reader :findings

      def initialize
        @findings = Hash.new { |h, k| h[k] = [] }
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
        all_findings.none? { |f| f.status == :error }
      end

      # All error findings across sections
      def errors
        all_findings.select { |f| f.status == :error }
      end

      # All warning findings across sections
      def warnings
        all_findings.select { |f| f.status == :warning }
      end

      # Findings for a specific section
      # @param name [Symbol] the section name
      # @return [Array<Finding>] findings for that section
      def section(name)
        findings[name]
      end

      private

      def all_findings
        findings.values.flatten
      end
    end
  end
end
