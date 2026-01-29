# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in reviewer.gemspec
gemspec

gem 'rake', '~> 13.2'

# Security auditing - always run in CI
gem 'bundler-audit'

# Self-review tools - not required for running tests
# Install with: bundle config set --local with lint && bundle install
group :lint, optional: true do
  # Ruby 3.4+ requires explicit racc (no longer a default gem)
  gem 'racc'

  # Style & Linting
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-rake'
  gem 'standard', '>= 1.35.1'

  # Code Quality & Complexity
  gem 'debride'
  gem 'fasterer'
  gem 'flay'
  gem 'flog'
  gem 'metric_fu'
  gem 'reek'
  gem 'rubycritic'

  # Security
  gem 'brakeman'

  # Documentation
  gem 'inch'
  gem 'yardstick'

  # Formatting
  gem 'rufo'

  # Compliance
  gem 'license_finder'
end
