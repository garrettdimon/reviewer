# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in reviewer.gemspec
gemspec

gem 'rake', '~> 13.2'

# Pin zeitwerk for Ruby 3.1 compatibility (2.7+ requires Ruby 3.2)
gem 'zeitwerk', '>= 2.6', '< 2.7'

# Security auditing - always run in CI
gem 'bundler-audit'

# Self-review tools - not required for running tests
# Install with: bundle install --with lint
group :lint, optional: true do
  gem 'flay'
  gem 'flog'
  gem 'reek'
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-rake'
end
