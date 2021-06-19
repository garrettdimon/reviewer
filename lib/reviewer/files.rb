# frozen_string_literal: true

require_relative 'git/staged'

module Reviewer
  # Generates the list of files to run the command against
  class Files
    attr_reader :files, :keywords

    def initialize(files: nil, keywords: nil)
      @files = files || Reviewer.arguments.files
      @keywords = keywords || Reviewer.arguments.keywords
    end

    def to_a
      file_list
    end

    def to_s
      file_list.join(',')
    end

    def inspect
      {
        files: files,
        keyword_files: keyword_files
      }
    end

    private

    def file_list
      @file_list ||= [
        *files,
        *keyword_files
      ].sort.uniq
    end

    def keyword_files
      return [] unless keywords.any?

      keywords.map do |keyword|
        send(keyword) if defined?(keyword)
      end.flatten.uniq
    end

    def staged
      # Use git for list of staged fields
      Reviewer::Git::Staged.new.list
    end
  end
end
