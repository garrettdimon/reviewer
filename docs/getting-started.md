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
