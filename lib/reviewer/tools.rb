# frozen_string_literal: true

module Reviewer
  # Provides convenient access to subsets of configured tools based on provided arguments,
  # configured tools, their enabled/disabled status, and more.
  class Tools
    include Enumerable

    # Provides an instance to work with for knowing which tools to run in a given context.
    # @param tags: nil [Array] the tags to use to filter tools for a run
    # @param tool_names: nil [type] the explicitly provided tool names to filter tools for a run
    #
    # @return [Reviewer::Tools] collection of tools based on the current run context
    def initialize(tags: nil, tool_names: nil)
      @tags       = tags
      @tool_names = tool_names
    end

    # The current state of all available configured tools regardless of whether they are disabled
    #
    # @return [Hash] hash representing all of the configured tools
    def to_h
      configured
    end
    alias inspect to_h

    # Provides a collection of all configured tools instantiated as Tool instances
    #
    # @return [Array<Tool>] the full collection of all Tool instances
    def all
      configured.keys.map { |tool_name| Tool.new(tool_name) }
    end
    alias to_a all

    # Provides a collection of all enabled tools instantiated as Tool instances
    #
    # @return [Array<Tool>] the full collection of all enabled Tool instances
    def enabled
      @enabled ||= all.keep_if(&:enabled?)
    end

    # Provides a collection of all explicitly-specified-via-command-line tools as Tool instances
    #
    # @return [Array<Tool>] the full collection of explicitly-specified tools for a run
    def specified
      all.keep_if { |tool| named?(tool) }
    end

    # Provides a collection of all tagged-via-command-line tools as Tool instances
    #
    # @return [Array<Tool>] the full collection of tagged-via-command-line tools for a run
    def tagged
      enabled.keep_if { |tool| tagged?(tool) }
    end

    # Uses the full context of a run to provide the filtered subset of tools to use. It takes into
    # consideration: tagged tools, explicitly-specified tools, configuration (enabled/disabled), and
    # any other relevant details that should influence whether a specific tool should be run as part
    # of the current batch being executed.
    #
    # @return [Array<Tool>] the full collection of should-be-used-for-this-run tools
    def current
      subset? ? (specified + tagged).uniq : enabled
    end

    private

    # Determines if the current run should include a subset of a tools or the full suite of enabled
    # tools by determining if any tool names or tags were provided that would reduce the full set to
    # only a subset of relevant tools.
    #
    # @return [Boolean] true if any tool names or tags are provided via the command line
    def subset?
      tool_names.any? || tags.any?
    end

    def configured
      @configured ||= Loader.configuration
    end

    def tags
      Array(@tags || Reviewer.arguments.tags)
    end

    def tool_names
      Array(@tool_names || Reviewer.arguments.keywords.for_tool_names)
    end

    def tagged?(tool)
      tool.enabled? && tags.intersection(tool.tags).any?
    end

    def named?(tool)
      tool_names.map(&:to_s).include?(tool.key.to_s)
    end
  end
end
