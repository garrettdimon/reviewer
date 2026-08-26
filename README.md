# [Reviewer](https://github.com/garrettdimon/reviewer)

Frictionless code quality.

[![build](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml)
[![coverage](https://img.shields.io/codecov/c/github/garrettdimon/reviewer?token=UuXUlQAA2e)](https://codecov.io/gh/garrettdimon/reviewer)
[![gem version](https://img.shields.io/gem/v/reviewer)](https://rubygems.org/gems/reviewer)

Reviewer wraps your code quality tools — tests, linters, security audits, formatters — into a single
command with a consistent interface. Configure once, run everywhere.

Reviewer works with any command-line tool but is built for Ruby projects. Auto-setup detects tools
from `Gemfile.lock`, and file mapping supports Minitest and RSpec conventions.

## Before & After

**Before** — five separate commands, each with their own flags:

```console
bundle exec bundle-audit check --no-update
bundle exec rake test
bundle exec rubocop --parallel
bundle exec fasterer
bundle exec reek lib/
```

**After:**

```console
rvw
```

```text
Bundle Audit Review Gem Dependencies for Security Issues
 ↳ bundle exec bundle-audit check --no-update
Success 0.8s

Minitest Unit Tests & Coverage
 ↳ bundle exec rake test
Success 4.2s

RuboCop Review Ruby Syntax & Formatting for Consistency
 ↳ bundle exec rubocop --parallel
Success 1.1s

✓ ~6.1 seconds for 3 tools
```

## Install & Setup

Reviewer requires Ruby 3.2 or newer.

```console
gem install reviewer
rvw init
rvw
```

Or add `gem 'reviewer'` to the project's `Gemfile` before running `bundle install`.

See [Getting started](docs/getting-started.md) for manual setup and the first review.

## Configuration

See the [configuration reference](docs/configuration.md) for the supported `.reviewer.yml` schema,
command composition, and file targeting.

## Documentation

- [Documentation index](docs/README.md)
- [Usage](docs/usage.md)
- [Recipes](docs/recipes.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Ruby API reference](https://www.rubydoc.info/gems/reviewer)

## License

MIT License — see [LICENSE.txt](LICENSE.txt).

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
