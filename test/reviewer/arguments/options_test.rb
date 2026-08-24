# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class OptionsTest < Minitest::Test
      def test_defines_every_documented_flag
        result = Slop.parse([]) { |opts| Options.configure(opts) }

        %i[files tags raw json format version help capabilities].each do |flag|
          assert result.options.any? { |o| o.key == flag }, "Expected --#{flag} to be defined"
        end
      end

      def test_parses_list_and_toggle_flags
        result = Slop.parse(%w[-f a.rb,b.rb -t ruby,style --json]) { |opts| Options.configure(opts) }

        assert_equal %w[a.rb b.rb], result[:files]
        assert_equal %w[ruby style], result[:tags]
        assert result[:json]
      end

      def test_format_defaults_to_streaming
        result = Slop.parse([]) { |opts| Options.configure(opts) }

        assert_equal 'streaming', result[:format]
      end
    end
  end
end
