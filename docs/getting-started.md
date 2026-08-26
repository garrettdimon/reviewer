# Getting started

Reviewer requires Ruby 3.2 or newer. It coordinates the commands a project owns in `.reviewer.yml`.
Doctor can also surface known tool signals without deciding how those tools should run.

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

## Inspect the project

From the project root, run:

```console
rvw doctor
```

Doctor separates configured tools from discoveries that are not yet configured:

```text
Reviewer Doctor

Configuration
  ✓ .reviewer.yml is valid

Configured tools
  Minitest (tests)
    Review         bundle exec rake test
    Files          *_test.rb → minitest
    Configured in  .reviewer.yml › tests

Discoveries
  RuboCop
    Discovered via Gemfile.lock › rubocop
                   .rubocop.yml

  ESLint
    Command        eslint .
    Discovered via package.json › scripts.lint
                   eslint.config.js

Environment
  ✓ Ruby 3.4.5 · git 2.50.1 · repository

Configuration valid · 1 configured · 2 discovered
```

`Configured tools` reflects `.reviewer.yml`. `Discoveries` lists what Doctor observed and the
source of each observation. A package-script command is shown exactly as written in `package.json`;
Reviewer does not infer a package manager, installation method, file target, or format command.

## Write the configuration

Use the project files named by Doctor, existing development instructions, and commands that already
work for the project. A human or agent can then write the smallest valid `.reviewer.yml`:

```yaml
tests:
  commands:
    review: bundle exec rake test
```

The YAML key is also the selector used on the command line. See the
[configuration reference](configuration.md) for every supported setting and
[recipes](recipes.md) for more examples.

Run Doctor again before the first review:

```console
rvw doctor
rvw
```

Doctor never writes `.reviewer.yml`. Missing or invalid configuration is reported in the
`Configuration` section while discoveries remain available.

### JSON for agents and scripts

`rvw doctor --json` returns the same report as structured data without terminal styling:

```json
{
  "schema_version": 1,
  "configuration": {
    "path": ".reviewer.yml",
    "state": "valid",
    "findings": []
  },
  "configured_tools": [
    {
      "key": "tests",
      "name": "Minitest",
      "skip_in_batch": false,
      "commands": {
        "review": "bundle exec rake test"
      },
      "files": {
        "pattern": "*_test.rb",
        "map_to_tests": "minitest"
      },
      "source": {
        "path": ".reviewer.yml",
        "location": "tests"
      }
    }
  ],
  "discoveries": [
    {
      "key": "eslint",
      "name": "ESLint",
      "observations": [
        {
          "kind": "command",
          "value": "eslint .",
          "source": {
            "path": "package.json",
            "location": "scripts.lint"
          }
        }
      ]
    }
  ],
  "environment": [
    {
      "name": "ruby",
      "status": "ok",
      "value": "3.4.5"
    }
  ],
  "summary": {
    "configured_tools": 1,
    "discoveries": 1,
    "configuration_issues": 0,
    "environment_warnings": 0
  }
}
```

## Existing configurations and deprecated init

Existing `.reviewer.yml` files remain valid and unchanged; no migration is required. Keep customized,
pinned, Yarn, pnpm, or other project-specific commands rather than deleting the file to regenerate it.

`rvw init` remains available for one deprecation cycle and retains its existing generation behavior.
It now prints a warning directing setup work to Doctor. Generated files are ordinary project-owned
configuration and may be edited like any other `.reviewer.yml`.

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
