# frozen_string_literal: true

require 'json'

module Reviewer
  # Provides machine-readable output describing available tools and usage patterns.
  # Designed for AI agents and automation tools to discover and use Reviewer correctly.
  #
  # @example
  #   puts Reviewer::Capabilities.new.to_json
  class Capabilities
    attr_reader :tools

    # Creates a capabilities report for machine-readable tool discovery
    # @param tools [Tools] the tools collection to report on
    #
    # @return [Capabilities]
    def initialize(tools:)
      @tools = tools
    end

    KEYWORDS = {
      staged: 'Files staged for commit',
      unstaged: 'Files with unstaged changes',
      modified: 'All changed files',
      untracked: 'New files not yet tracked'
    }.freeze

    SCENARIOS = {
      before_commit: 'rvw staged',
      during_development: 'rvw modified',
      full_review: 'rvw'
    }.freeze

    # Convert capabilities to a hash representation
    #
    # @return [Hash] structured capabilities data
    def to_h
      {
        version: VERSION,
        tools: tools_data,
        keywords: KEYWORDS,
        scenarios: SCENARIOS
      }
    end

    # Convert capabilities to formatted JSON string
    #
    # @return [String] JSON representation of capabilities
    def to_json(*_args)
      JSON.pretty_generate(to_h)
    end

    private

    # Build tool data from configured tools
    #
    # @return [Array<Hash>] array of tool capability hashes
    def tools_data
      tools.all.map { |tool| tool_data(tool) }
    end

    # Build capability data for a single tool
    #
    # @param tool [Tool] the tool to extract data from
    # @return [Hash] tool capability hash
    def tool_data(tool)
      {
        key: tool.key.to_s,
        name: tool.name,
        description: tool.description,
        tags: tool.tags,
        skip_in_batch: tool.skip_in_batch?,
        commands: {
          review: tool.reviewable?,
          format: tool.formattable?
        }
      }
    end
  end
end
