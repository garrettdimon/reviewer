require_relative './reviewer_reporter'

module Minitest
  def self.plugin_reviewer_options(_opts, _options)
  end

  def self.plugin_reviewer_init(_options)
    # Clean out the existing reporters.
    self.reporter.reporters = []

    # Use Reviewer as the sole reporter.
    self.reporter << ReviewerReporter.new
  end
end
