# Configuration

Reviewer reads `.reviewer.yml` from the current directory. The file maps a tool key to its settings;
only `commands.review` is required.

```yaml
rubocop:
  commands:
    review: bundle exec rubocop --parallel
```

Run that tool with `rvw rubocop`. Run every tool included in the default batch with `rvw`.

## Tool order and selection

Tools run in YAML order. Put checks that should stop the review near the beginning: Reviewer stops
after the first executed failure, while a missing executable is reported and the batch continues.

Set `skip_in_batch: true` to exclude a tool from bare `rvw` while keeping it available by an
explicit tool key. Tags select enabled tools that share a configured category.

```yaml
brakeman:
  name: Brakeman
  description: Scan a Rails application for security issues
  tags: [ruby, security]
  skip_in_batch: true
  commands:
    review: bundle exec brakeman --no-pager -q
```

`disabled` is deprecated. Existing configurations still treat `disabled: true` as
`skip_in_batch: true`, but `skip_in_batch` wins when both keys are present. Replace `disabled` when
editing a configuration.

## Commands

```yaml
bundle_audit:
  commands:
    install: bundle exec gem install bundler-audit
    prepare: bundle exec bundle-audit update
    review: bundle exec bundle-audit check --no-update
    format: bundle exec bundle-audit update
    max_exit_status: 0
```

| Setting | Behavior |
|---|---|
| `commands.review` | Required command used by `rvw` |
| `commands.format` | Command used by `fmt`; tools without one are skipped during formatting |
| `commands.prepare` | Runs before review or format at most once every six hours; failed attempts are cached too |
| `commands.install` | Recovery hint that Reviewer may display; Reviewer does not execute it |
| `commands.max_exit_status` | Highest review-command status considered successful; defaults to `0` |

Commands in `.reviewer.yml` are shell strings owned by the project. Reviewer preserves each saved
command as configured, then applies only the explicit composition settings below. `commands.install`
is display-only: Reviewer has no installer and never executes it. Projects may replace or pin any
saved command without changing Reviewer's behavior.

## Command composition

Reviewer builds an executable command in this order:

1. Environment assignments from `env`.
2. The selected base command.
3. Configured `flags` for review commands.
4. Resolved file arguments when file targeting applies.

The base command is preserved as configured. With targeted files, `files.review` or `files.format`
replaces the corresponding base command when present; Reviewer then appends the same configured flags
and file arguments.

```yaml
tests:
  commands:
    review: bundle exec rake test
  files:
    review: bundle exec ruby -Itest -e 'ARGV.each { |file| require File.expand_path(file) }'
    pattern: "*_test.rb"
    map_to_tests: minitest
```

## File targeting

```yaml
rubocop:
  commands:
    review: bundle exec rubocop
    format: bundle exec rubocop --autocorrect
  files:
    review: bundle exec rubocop
    format: bundle exec rubocop --autocorrect
    flag: ""
    separator: " "
    pattern: "*.rb"
    map_to_tests: minitest
```

| Setting | Behavior |
|---|---|
| `files.review` | Replaces `commands.review` when files are targeted |
| `files.format` | Replaces `commands.format` when files are targeted |
| `files.flag` | Prefix before the resolved file list; empty means bare paths |
| `files.separator` | Joins multiple paths; defaults to one space |
| `files.pattern` | Keeps matching paths before the command runs |
| `files.map_to_tests` | Maps Ruby source paths to existing `minitest` or `rspec` test paths |

Slashless patterns match each path's basename. Patterns containing `/` match normalized
repository-relative paths with pathname semantics. In path patterns, `**/` crosses directory
boundaries while bare `**` does not; brace alternatives such as `'{lib,test}/**/*.rb'` are
supported. Source-to-test mapping runs before filtering, nonexistent resolved paths are omitted,
and matched paths retain their original form when appended to the command.

Source-to-test mapping recognizes Ruby files under `app/` and `lib/`, preserves matching test files,
and omits mapped paths that do not exist.

## Environment and flags

```yaml
tests:
  commands:
    review: bundle exec rake test
  env:
    testopts: --seed=$SEED
  flags:
    verbose:
```

Environment keys are uppercased and prepended as `KEY=value`. Values containing spaces are quoted.
`$SEED` is replaced with a consistent random seed that `rvw failed` reuses.

Flags apply only to review commands. A one-character key becomes a short flag such as `-v`; longer
keys become long flags such as `--verbose`. Empty values produce a switch, and values containing
spaces are quoted.

## Links and failure guidance

```yaml
rubocop:
  links:
    home: https://rubocop.org
    install: https://docs.rubocop.org/rubocop/installation.html
    ignore_syntax: https://docs.rubocop.org/rubocop/configuration.html
    disable_syntax: https://docs.rubocop.org/rubocop/configuration.html
  commands:
    review: bundle exec rubocop
```

`links.ignore_syntax` and `links.disable_syntax` may be shown after a review failure. Link values are
informational and are never executed.

## Summary details

Summary output can extract a detail from captured standard output:

```yaml
tests:
  commands:
    review: bundle exec rake test
  summary:
    pattern: "(\\d+) tests?"
    label: "\\1 tests"
```

`summary.pattern` is matched case-insensitively. Numbered captures such as `\\1` in
`summary.label` are replaced with values from the match.

## Complete example

The repository's [example configuration](../.reviewer.example.yml) is the copyable reference for all
supported settings. For task-oriented examples, see [recipes](recipes.md). Return to the
[documentation index](README.md).
