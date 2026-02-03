# [Reviewer](https://github.com/garrettdimon/reviewer)

Frictionless code quality.

[![build](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/garrettdimon/reviewer/actions/workflows/main.yml)
[![coverage](https://img.shields.io/codecov/c/github/garrettdimon/reviewer?token=UuXUlQAA2e)](https://codecov.io/gh/garrettdimon/reviewer)
[![gem version](https://img.shields.io/gem/v/reviewer)](https://rubygems.org/gems/reviewer)

Reviewer wraps your code quality tools — tests, linters, security audits, formatters — into a single command with a consistent interface. Configure once, run everywhere.

Reviewer works with any command-line tool but is built for Ruby projects. Auto-setup detects tools from `Gemfile.lock`, and file mapping supports Minitest and RSpec conventions.

## Before & After

**Before** — five separate commands, each with their own flags:

```
bundle exec bundle-audit check --no-update
bundle exec rake test
bundle exec rubocop --parallel
bundle exec fasterer
bundle exec reek lib/
```

**After:**

```
rvw
```

```
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

```bash
gem install reviewer
```

Or add to your Gemfile:

```ruby
gem 'reviewer'
```

**Requires Ruby 3.2+**

Then auto-generate `.reviewer.yml` from your `Gemfile.lock`:

```bash
rvw init
```

```
Created .reviewer.yml

Detected tools:
  Bundle Audit            bundler-audit in Gemfile.lock
  RuboCop                 rubocop in Gemfile.lock, .rubocop.yml
  Minitest                minitest in Gemfile.lock, test/ directory

Configure further:    https://github.com/garrettdimon/reviewer#configuration
Run `rvw` to review your code.
```

Now run it:

```bash
rvw
```

## Usage

### Run a single tool without remembering its flags

```bash
rvw rubocop
```

Instead of `bundle exec rubocop --parallel`, use the YAML key. Reviewer applies your configured flags and options automatically.

### Run a subset of tools by tag

```bash
rvw security
```

Instead of maintaining lists of which tools to run in which context, tag them in `.reviewer.yml` and filter on the fly:

```
rvw security ─── bundle-audit check --no-update
             └── brakeman --no-pager -q
```

Tags work as positional args or with `-t ruby`. Tag ideas: language (`ruby`, `css`), purpose (`security`, `syntax`), speed (`fast`, `slow`), context (`ci`, `pr`).

### Review only staged files

```bash
rvw staged
```

Instead of figuring out each tool's syntax for targeting files, use a keyword. Reviewer resolves git status, filters by each tool's file pattern, maps source files to test files, and applies each tool's file-passing syntax:

```
rvw staged ─── rubocop lib/reviewer.rb lib/reviewer/batch.rb
           ├── rake test TEST=test/reviewer_test.rb test/reviewer/batch_test.rb
           └── fasterer lib/reviewer.rb lib/reviewer/batch.rb
```

One command. Three tools. Each gets only its relevant files in its expected format.

Also: `unstaged`, `modified`, `untracked`.

### Target specific files

```bash
rvw -f app/models/user.rb,test/models/user_test.rb
```

Pass files once. Reviewer handles whether the tool expects a flag, a bare path, or something else.

### Re-run only what failed

```bash
rvw failed
```

Reviewer tracks which tools failed. Fix the issue, re-run only those.

### Combine everything

```bash
rvw rubocop staged
rvw -t ruby modified
rvw tests -f test/models/user_test.rb
```

Tools, tags, keywords, and files compose naturally.

### Auto-fix with formatters

```bash
fmt
fmt rubocop staged
```

Same interface as `rvw`, but runs the `format` command for each tool. Only tools with a `format` command configured will run.

### Output formats

| Flag | Format | Use case |
|------|--------|----------|
| _(default)_ | Streaming | Development — see output as it runs |
| `--format summary` | Summary | Quick pass/fail with timing per tool |
| `-j` / `--json` | JSON | CI, scripting, agent integration |
| `-r` / `--raw` | Raw | Force direct output, no capturing |

## Configuration

### Minimal example

The only requirement is a `review` command:

```yaml
rubocop:
  commands:
    review: bundle exec rubocop --parallel
```

### Full example

```yaml
rubocop:
  name: RuboCop
  description: Review Ruby syntax and formatting for consistency
  tags: [ruby, syntax]
  commands:
    install: bundle exec gem install rubocop
    prepare: bundle exec rubocop --regenerate-todo
    review: bundle exec rubocop --parallel
    format: bundle exec rubocop --auto-correct
  files:
    flag: ""
    separator: " "
    pattern: "*.rb"
    map_to_tests: minitest
  links:
    home: https://rubocop.org
    install: https://docs.rubocop.org/rubocop/installation.html
  env:
    RUBOCOP_OPTS: --color
  flags:
    color:
```

### Options reference

| Option | Description |
|--------|-------------|
| `name` | Display name |
| `description` | What the tool does |
| `tags` | Categories for filtering (`[ruby, security]`) |
| `skip_in_batch` | Set `true` to exclude from `rvw` but still run with `rvw tool_name` |
| `commands.review` | Command to run for `rvw` **(required)** |
| `commands.format` | Command to run for `fmt` |
| `commands.install` | Command to install the tool |
| `commands.prepare` | Command to run before review (cached 6 hours) |
| `commands.max_exit_status` | Treat exit codes up to this value as success |
| `files.review` | Command to use instead of `commands.review` when files are scoped |
| `files.format` | Command to use instead of `commands.format` when files are scoped |
| `files.flag` | CLI flag for passing files (empty string = bare paths) |
| `files.separator` | How to join multiple file paths (default: space) |
| `files.pattern` | Glob pattern to filter files (e.g., `*.rb`) |
| `files.map_to_tests` | Map source files to test files (`minitest` or `rspec`) |
| `links.home` | Project homepage |
| `links.install` | Installation instructions |
| `env` | Environment variables to set when running |
| `flags` | CLI flags to append to the review command |

### File-scoped commands

Some tools use different commands for running the full suite vs. targeting specific files. Use `files.review` (or `files.format`) to specify an alternative command when files are passed:

```yaml
tests:
  commands:
    review: bundle exec rake test
  files:
    review: bundle exec ruby -Itest
    pattern: "*_test.rb"
    map_to_tests: minitest
```

`rvw` runs `bundle exec rake test` (full suite). `rvw staged` or `rvw tests -f test/models/user_test.rb` runs `bundle exec ruby -Itest` with the resolved files appended. The standard `files.flag` and `files.separator` still apply when appending files to the file-scoped command.

### Notes

- **Tool ordering** — Tools run in the order they appear in `.reviewer.yml`. Put fast tools first for quicker feedback.
- **Environment variables** — Use `env` for things like `TESTOPTS: --seed=$SEED`. The `$SEED` placeholder is replaced with a consistent random seed across runs.
- **Flags** — Keys with no value become boolean flags (`color:` becomes `--color`). Keys with values become `--key value`.
- **Prepare caching** — The `prepare` command only runs if it hasn't been run in the last 6 hours, saving time on commands like `bundle-audit update`.

## Workflows

### Pre-commit

Review only what you're about to commit:

```bash
rvw staged
```

### Pull request

Review everything that changed:

```bash
rvw modified
```

### CI

Full review with JSON output for parsing:

```bash
rvw --json
```

Reviewer exits `0` when all tools pass, or with the highest exit status from any failing tool. Skipped and missing tools don't affect the exit code. This means `rvw` works directly as a CI gate — no wrapper script needed.

### Development

Run the full suite:

```bash
rvw
```

### Hotfix

Run just security and tests on changed files:

```bash
rvw -t security modified
rvw tests modified
```

### After a failure

Fix the issue, then re-run only what failed:

```bash
rvw failed
```

## Agent Integration

For AI agents and automation tools, use `--capabilities` to discover available tools:

```bash
rvw --capabilities
```

This outputs JSON describing all configured tools, keywords, and common scenarios.

## License

MIT License — see [LICENSE.txt](LICENSE.txt)

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
