# frozen_string_literal: true

require 'test_helper'
require 'open3'

class WarningsTest < Minitest::Test
  # Loading in a subprocess is the only way to observe load-time warnings: by
  # the time this suite runs, test_helper has already required the library.
  def test_loading_the_library_emits_no_warnings
    _stdout, stderr, status = Open3.capture3('bundle', 'exec', 'ruby', '-w', '-Ilib', '-e', 'require "reviewer"')

    assert status.success?, stderr

    # Scoped to this library so a dependency's warnings cannot fail the build
    own_warnings = stderr.lines.grep(%r{lib/reviewer/.*warning:})

    assert_empty own_warnings, "Loading Reviewer emitted warnings:\n#{own_warnings.join}"
  end
end
