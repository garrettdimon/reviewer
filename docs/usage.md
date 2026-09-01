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

File selectors resolve paths from Git:

| Keyword | Files |
|---|---|
| `staged` | Staged changes |
| `unstaged` | Unstaged changes |
| `modified` | Staged and unstaged changes compared with `HEAD` |
| `untracked` | Untracked, non-ignored files |

`failed` selects tools whose last executed review failed and, when available, reuses each tool's
stored failed file paths. File-aware tools retry those paths; tools without file support retry their
full command. A tool remains selected until an executed review records a pass. Skipped, missing,
formatted, and not-run tools leave that review history unchanged, so a passing scoped run can coexist
with tools still selected by `rvw failed`.

Selections compose:

```console
rvw rubocop staged
rvw -t ruby modified
rvw tests -f test/reviewer_test.rb
```

File-scoped requests skip tools without a `files:` configuration instead of running their
full-project command. Bare `rvw` remains the full configured review.

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
| Default | Streams a single tool; captures batches and reports any fail-fast tail |
| `--format summary` | One result line per runnable tool plus explicit state totals |
| `-j`, `--json`, or `--format json` | Structured JSON for automation |
| `-r` or `--raw` | Direct passthrough output |

When a tool's [summary configuration](configuration.md#summary-details) matches its standard output,
its JSON result includes the project-defined display text as `detail_summary`. The key is absent
when no summary is available.

Use `rvw --capabilities` to print JSON describing configured tools, tags, keywords, and common
agent workflows without running review commands.

## Consume review JSON

Review JSON uses `schema_version: 1`. Each tool has one authoritative `state`; its `success` value is
true only when that tool executed and passed. Top-level `success` remains the aggregate verdict, so
it can be true when every represented tool was skipped, missing, or not run.

State describes the terminal disposition Reviewer acts on. For executed failures, `exit_status`,
`stdout`, and `stderr` carry the tool or process diagnostics that caused that failure.

| Tool state | Meaning | Tool `success` | Exit effect |
|---|---|---:|---|
| `passed` | The command executed within its configured threshold | `true` | None |
| `failed` | The command executed outside its configured threshold | `false` | Exit `1` |
| `skipped` | Requested files did not match the tool | `false` | None |
| `missing` | The executable was unavailable | `false` | None in 1.1 |
| `not_run` | An earlier tool failed and fail-fast stopped the batch | `false` | None |

This compact example shows the difference between tool and aggregate success:

```json
{
  "schema_version": 1,
  "success": true,
  "summary": {
    "total": 1,
    "passed": 0,
    "failed": 0,
    "skipped": 1,
    "missing": 0,
    "not_run": 0,
    "duration": 0
  },
  "tools": [
    {
      "tool": "rubocop",
      "name": "RuboCop",
      "command_type": "review",
      "command": null,
      "state": "skipped",
      "success": false,
      "exit_status": null,
      "duration": null,
      "stdout": null,
      "stderr": null,
      "skipped": true
    }
  ]
}
```

Every summary contains `total`, all five state counts, and `duration`; the state counts sum to
`total`. Fail-fast still stops execution, but later runnable tools remain visible as `not_run`.

| Envelope | Required top-level fields | Absent fields |
|---|---|---|
| Nonempty report | `schema_version`, `success`, `summary`, `tools` | `state`, `message`, `error` |
| Empty report | `schema_version`, `state: "empty"`, `success: true`, `message`, zero summary, `tools: []` | `error` |
| Selector error | `schema_version`, `state: "error"`, `error`, zero summary, `tools: []` | `success`, `message` |

| Tool state | Execution fields | Compatibility flags |
|---|---|---|
| `passed`, `failed` | Command, status, and duration are populated; nil output fields are omitted | Omitted |
| `missing` | Command is present, status is `127`, and nil output fields are omitted | `missing: true` |
| `skipped`, `not_run` | Command, status, duration, stdout, and stderr are explicit JSON null | `skipped: true` only for `skipped` |

Consumers should use `state` whenever `schema_version >= 1`. For older payloads, check `skipped`,
then `missing`, then derive passed or failed from `success`. Compared with older payloads, a skipped
tool now has `success: false`, and its unavailable execution fields are null instead of zero or
omitted. Valid 1.x `Runner::Result.new` keyword calls and the legacy true-valued payload flags remain
supported through the 1.x line.

## Exit statuses

| Status | Meaning |
|---|---|
| `0` | Every executed tool passed; skipped, missing, and not-run tools do not fail the run |
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
