# frozen_string_literal: true

require_relative 'git/staged'

module Reviewer
  class Arguments
    class Keywords
      module Git
        BASE_COMMAND = [
          'git',
          '--no-pager'
        ].freeze
      end
    end
  end
end
