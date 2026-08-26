# Getting started

Reviewer requires Ruby 3.2 or newer. It works with any command-line tool and can detect common Ruby
and JavaScript tools when generating a project configuration.

## Install

Install the gem directly:

```console
gem install reviewer
```

Or add it to a project's `Gemfile` and install the bundle:

```ruby
gem 'reviewer'
```

```console
bundle install
```

## Generate a configuration

From the project root, run:

```console
rvw init
```

Reviewer inspects the project for tools it recognizes and writes their commands to `.reviewer.yml`.
Review that file before running it: its commands execute with the same permissions as your shell.

If `.reviewer.yml` already exists, `rvw init` leaves it unchanged. If no supported tools are found,
Reviewer prints a link to the [configuration reference](configuration.md) instead.

### Update an existing generated configuration

No migration is required. Commands in an existing `.reviewer.yml` remain project-owned, so keep
Yarn, pnpm, or pinned commands when they reflect the project's policy. To adopt Reviewer's current
generated defaults, edit only the applicable `commands.review` and `commands.format` values; do not
delete a customized file just to regenerate it.

| Tool | Previous generated forms | Current generated values |
|---|---|---|
| ESLint | `yarn eslint .` or `pnpm exec eslint .`, with `--fix` for format | Review: `npx eslint .`; format: `npx eslint . --fix` |
| Prettier | `yarn prettier --check .` or `pnpm exec prettier --check .`, with `--write .` for format | Review: `npx prettier --check .`; format: `npx prettier --write .` |
| Stylelint | `yarn stylelint "**/*.css"` or `pnpm exec stylelint "**/*.css"`, with `--fix` for format | Review: `npx stylelint "**/*.css"`; format: `npx stylelint "**/*.css" --fix` |
| TypeScript | `npx tsc --noEmit`, `yarn tsc --noEmit`, or `pnpm exec tsc --noEmit` | Review: `npx --package=typescript tsc --noEmit` |
| Biome | `yarn @biomejs/biome check .` or `pnpm exec @biomejs/biome check .`, with `--fix` for format | Review: `npx @biomejs/biome check .`; format: `npx @biomejs/biome check . --fix` |

These defaults use npm's normal [`npx` resolution behavior](https://docs.npmjs.com/cli/v11/commands/npx/),
which may acquire a missing package. Reviewer does not run a separate installer. Projects may
replace these commands or pin package versions in their own configuration.

## Configure manually

Auto-detection is optional. The smallest valid `.reviewer.yml` names a tool and provides its review
command:

```yaml
tests:
  commands:
    review: bundle exec rake test
```

The YAML key is also the selector used on the command line. See the
[configuration reference](configuration.md) for every supported setting and
[recipes](recipes.md) for more examples.

## Run the first review

Run every tool included in the default batch:

```console
rvw
```

Run one configured tool by key:

```console
rvw tests
```

Reviewer stops after the first tool failure so the output stays focused. Missing executables are
reported but do not make the review fail.

Next, read the [usage guide](usage.md). Return to the [documentation index](README.md).
