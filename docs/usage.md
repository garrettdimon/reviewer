# Usage

`rvw` reviews code; `fmt` runs configured formatting commands. Both commands use the tool keys,
tags, file keywords, and file options defined by the project.

## Inspect configuration and discoveries

Run Doctor to see validly configured tools, project discoveries, and environment checks:

```console
rvw doctor
```

The human report uses separate `Configured tools` and `Discoveries` sections. Configured entries show
their saved commands and `.reviewer.yml` location. Discoveries show each observed tool with the file,
directory, resolved gem, or direct package script that produced it. Doctor does not write configuration.

Use JSON when another program or agent will consume the report:

```console
rvw doctor --json
```

The JSON schema includes `configuration`, `configured_tools`, `discoveries`, `environment`, and a
count summary. Missing or invalid Reviewer configuration still produces a report and exits successfully;
unexpected internal failures retain a nonzero status. See the concrete outputs in
[Getting started](getting-started.md#inspect-the-project).

## Select tools

Run every tool not marked `skip_in_batch`:

```console
rvw
```

Run one tool by its `.reviewer.yml` key or run every enabled tool carrying a tag:

```console
rvw rubocop
rvw security
rvw -t security
```

Tool keys and tags may be combined. An unrecognized selector is a usage error and exits with status
`2`; Reviewer suggests a close match when one is available.

## Target files

Pass a comma-separated list once and let each tool apply its configured file syntax:

```console
rvw -f lib/reviewer.rb,test/reviewer_test.rb
```

File keywords resolve paths from Git:

| Keyword | Files |
|---|---|
| `staged` | Staged changes |
| `unstaged` | Unstaged changes |
| `modified` | Staged and unstaged changes compared with `HEAD` |
| `untracked` | Untracked, non-ignored files |
| `failed` | Tools, and when available files, from the previous failed run |

Selections compose:

```console
rvw rubocop staged
rvw -t ruby modified
rvw tests -f test/reviewer_test.rb
```

The [configuration reference](configuration.md#file-targeting) describes filtering, file-scoped
commands, and Minitest/RSpec source-to-test mapping.

## Format

`fmt` accepts the same selectors and file targeting as `rvw`, but it runs only tools with a
`commands.format` entry:

```console
fmt
fmt rubocop staged
```

## Choose output

| Option | Output |
|---|---|
| Default | Streams a single tool; captures batches and prints actionable output |
| `--format summary` | One result line per tool plus totals; unmatched tools are labeled skipped |
| `-j`, `--json`, or `--format json` | Structured JSON for automation |
| `-r` or `--raw` | Direct passthrough output |

Use `rvw --capabilities` to print JSON describing configured tools, tags, keywords, and common
agent workflows without running review commands.

## Exit statuses

| Status | Meaning |
|---|---|
| `0` | Every executed tool passed; skipped and missing tools do not fail the run |
| `1` | At least one executed tool failed |
| `2` | The request used an unrecognized tool, tag, or keyword |

A tool may pass with a nonzero process status when its `commands.max_exit_status` allows it. Reviewer
returns its own status above instead of forwarding the tool's process status.

## Workflow examples

Before a commit, review staged files:

```console
rvw staged
```

For a pull request, review all local changes:

```console
rvw modified
```

After a failure, rerun only the failed tools:

```console
rvw failed
```

In CI, request JSON and use Reviewer's exit status as the gate:

```console
rvw --json
```

See [recipes](recipes.md) for configuration examples. Return to the
[documentation index](README.md).
