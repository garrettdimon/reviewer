# frozen_string_literal: true

require_relative 'git/staged'
require_relative 'git/unstaged'
require_relative 'git/modified'
require_relative 'git/untracked'

module Reviewer
  module Keywords
    module Git
      BASE_COMMAND = [
        'git',
        '--no-pager'
      ].freeze
    end
  end
end
