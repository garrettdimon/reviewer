# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in reviewer.gemspec
gemspec

gem 'rake', '~> 13.2'

# Security auditing - always run in CI
gem 'bundler-audit'

# Reviewer's own quality gate. Installed by default so a fresh clone can run
# everything a pull request is expected to pass.
gem 'racc' # Ruby 3.4+ requires explicit racc (no longer a default gem)
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-rake'

# Tools Reviewer configures to exercise its own integration surface, not to
# develop the gem. Different exit-code semantics, output shapes, prepare steps
# and file scoping - useful to run against, unnecessary to install.
# Enable with: bundle config set --local with dogfood && bundle install
group :dogfood, optional: true do
  gem 'brakeman'       # Rails-oriented scanner; exercises skip_in_batch
  gem 'debride'        # Dead code
  gem 'fasterer'       # Performance suggestions
  gem 'flay'           # Structural duplication
  gem 'flog'           # Complexity scoring
  gem 'license_finder' # Slow, compliance-oriented; exercises the slow tag
  gem 'reek'           # Design smells
end
