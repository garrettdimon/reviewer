# [Reviewer](https://github.com/garrettdimon/reviewer)

Run multiple code review tools with a single command.

[![build](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml)
[![coverage](https://img.shields.io/codecov/c/github/garrettdimon/reviewer?token=UuXUlQAA2e)](https://codecov.io/gh/garrettdimon/reviewer)
[![gem version](https://img.shields.io/gem/v/reviewer)](https://rubygems.org/gems/reviewer)

## Installation

```bash
gem install reviewer
```

Or add to your Gemfile:

```ruby
gem 'reviewer'
```

**Requires Ruby 3.2+**

## Quick Start

1. Create a `.reviewer.yml` in your project root (see [Configuration](#configuration))
2. Run `rvw` to review your code

```bash
rvw                    # Run all enabled tools
rvw rubocop tests      # Run specific tools
rvw -t ruby            # Run tools tagged with 'ruby'
rvw staged             # Review only staged files
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `rvw` | Run review commands for all enabled tools |
| `fmt` | Run format commands for tools that support it |

### Git Keywords

Target files by git status:

| Keyword | Description |
|---------|-------------|
| `staged` | Files staged for commit |
| `unstaged` | Files with unstaged changes |
| `modified` | All changed files (staged + unstaged) |
| `untracked` | New files not yet tracked |
| `failed` | Re-run tools that failed in the previous run |

### Flags

| Flag | Description |
|------|-------------|
| `-t, --tags` | Filter tools by tag |
| `-f, --files` | Specify files to review |
| `-r, --raw` | Force passthrough output |
| `-j, --json` | Output results as JSON |
| `-c, --capabilities` | Output tool capabilities as JSON |

## Configuration

Create `.reviewer.yml` in your project root:

```yaml
rubocop:
  name: RuboCop
  description: Ruby style and lint checking
  tags: [ruby, style]
  commands:
    review: bundle exec rubocop --parallel
    format: bundle exec rubocop --autocorrect
  files:
    pattern: '*.rb'

tests:
  name: Minitest
  description: Run test suite
  tags: [ruby, tests]
  commands:
    review: bundle exec rake test
  files:
    pattern: '*_test.rb'
    map_to_tests: minitest
```

### Tool Options

| Option | Description |
|--------|-------------|
| `name` | Display name |
| `description` | What the tool does |
| `tags` | Categories for filtering |
| `disabled` | Set `true` to skip |
| `commands.review` | Command to run for `rvw` |
| `commands.format` | Command to run for `fmt` |
| `commands.install` | Command to install the tool |
| `commands.prepare` | Command to run before review (cached 6 hours) |
| `files.pattern` | Glob pattern to filter files (e.g., `*.rb`) |
| `files.map_to_tests` | Map source files to test files (`minitest` or `rspec`) |

## Agent Integration

For AI agents and automation tools, use `--capabilities` to discover available tools:

```bash
rvw --capabilities
```

This outputs JSON describing all configured tools, keywords, and common scenarios.

## License

MIT License - see [LICENSE.txt](LICENSE.txt)

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
