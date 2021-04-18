# frozen_string_literal: true

require "test_helper"

module Reviewer
  class Tool
    class EnvTest < MiniTest::Test
      def setup
        @env_pairs = {
          environment: 'production',
          verbose: true,
        }
        @env = Reviewer::Tool::Env.new(@env_pairs)
      end

      def test_casts_to_a_string
        env_string = "ENVIRONMENT=production VERBOSE=true"
        assert_equal env_string, @env.to_s
        assert_equal env_string, "#{@env}"
      end

      def test_properly_format_nonstring_data_types
        assert_includes @env.to_a, "ENVIRONMENT=production"
        assert_includes @env.to_a, "VERBOSE=true"
      end
    end
  end
end
