# Releasing Reviewer

Reviewer releases have three gates: accept one exact commit from `origin/main`, prepare release
metadata through a pull request, then publish by pushing a version tag from the merged release
commit. A tag push starts publication and must not happen until the first two gates are complete.

## Gate 1: Accept the Candidate

Fetch `main`, fast-forward the local checkout, and record the candidate commit:

```bash
git fetch origin main
git status --short
git merge --ff-only origin/main
candidate_sha=$(git rev-parse HEAD)
test "$candidate_sha" = "$(git rev-parse origin/main)"
test -z "$(git status --porcelain)"
bundle check
```

The worktree must be clean, and `candidate_sha` must equal `origin/main`. Verify that exact commit
before changing the version:

1. Run focused contract tests for the release's changed behavior.
2. Exercise the checkout's `exe/rvw` and `exe/fmt` commands through representative CLI scenarios.
3. Run the checkout's `exe/rvw` in clean projects that use different test and analysis tools.
4. Preview the current package with `bundle exec rake release:dry_run`.

Record the commands and results with the candidate SHA. If `origin/main` changes, discard the prior
acceptance decision and repeat this gate for the new commit. A failure belongs in a focused defect
pull request; do not combine runtime fixes with release preparation.

## Gate 2: Prepare the Release Pull Request

Create a release branch from the accepted commit:

```bash
git switch -c release/X.Y.Z "$candidate_sha"
```

The release pull request contains metadata and release documentation only:

1. Set `Reviewer::VERSION` in `lib/reviewer/version.rb`.
2. Refresh `Gemfile.lock` so its local `reviewer` specification has the same version.
3. Leave a new empty `[Unreleased]` section in `CHANGELOG.md` and move the accepted changes into a
   dated `[X.Y.Z] - YYYY-MM-DD` section.
4. Put compatibility and upgrade notes before the feature and fix lists.
5. Update this guide when the release workflow itself changes.

Preview the versioned package and run Reviewer against the staged release changes:

```bash
bundle exec rake release:dry_run
git add lib/reviewer/version.rb Gemfile.lock CHANGELOG.md RELEASING.md
bundle exec rvw staged
```

Commit and push the release branch, then open a pull request into `main`. Do not push or force-push
release preparation directly to `main`. The pull request must pass these jobs from
`.github/workflows/main.yml`:

- `Security`
- `Changelog`
- `Version`
- `Test (Ruby 3.2)`
- `Test (Ruby 3.3)`
- `Test (Ruby 3.4)`
- `Test (Ruby 4.0)`

The maintainer reviews and merges the release pull request. Opening the pull request does not
authorize an agent to merge it.

## Gate 3: Publish from `main`

After the release pull request is merged, update a clean local `main`:

```bash
git fetch origin main
git switch main
git pull --ff-only
git status --short
```

Run the full preflight and preview the final package:

```bash
bundle exec rake release:preflight
bundle exec rake release:dry_run
```

`release:preflight` runs the full tests, dependency audit, and `release:check`. It belongs here
because `release:check` requires the current branch to be `main`. This is a release-manager step;
agents restricted to focused tests must stop and hand it to the maintainer.

Before tagging, confirm all of the following for the checked-out commit:

- `Reviewer::VERSION` matches the intended tag.
- `CHANGELOG.md` has a dated and complete section for the version.
- `HEAD` equals `origin/main` and the required CI jobs passed for that commit.
- RubyGems does not already contain the version.
- The version tag does not exist locally or remotely.

Pushing the tag triggers `.github/workflows/release.yml`, which publishes the gem and then creates
the GitHub Release. Treat the tag push as the irreversible publication trigger and require explicit
authorization immediately before running it:

```bash
release_sha=$(git rev-parse HEAD)
git merge-base --is-ancestor "$release_sha" origin/main
git tag vX.Y.Z "$release_sha"
git push origin vX.Y.Z
```

Never move or reuse a version tag after RubyGems has accepted that version.

## Verify the Published Artifact

Require all three publication results:

1. The [GitHub Actions `Release` workflow](https://github.com/garrettdimon/reviewer/actions/workflows/release.yml)
   succeeds.
2. [RubyGems](https://rubygems.org/gems/reviewer) lists the new Reviewer version.
3. [GitHub Releases](https://github.com/garrettdimon/reviewer/releases) contains the matching tag and
   changelog excerpt.

Install the public gem and run a focused smoke test in a clean project:

```bash
gem install reviewer -v X.Y.Z --no-document
rvw _X.Y.Z_ --version
rvw _X.Y.Z_ TOOL -f path/to/file --json
```

The published artifact must reproduce the accepted candidate's result.

## Versioning Policy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (`X.0.0`): incompatible public API or configuration changes
- **MINOR** (`X.Y.0`): backward-compatible features and deprecations
- **PATCH** (`X.Y.Z`): backward-compatible fixes

Dropping Ruby support, removing public APIs, or changing default configuration behavior
incompatibly requires a major release.

## One-Time Publishing Setup

### RubyGems Trusted Publishing

1. Open [RubyGems pending trusted publishers](https://rubygems.org/profile/oidc/pending_trusted_publishers).
2. Add a publisher with these values:
   - **Gem name:** `reviewer`
   - **Repository owner:** `garrettdimon`
   - **Repository name:** `reviewer`
   - **Workflow filename:** `release.yml`
   - **Environment:** `rubygems`

### GitHub Environment

In the repository settings, create an environment named `rubygems`. Add required reviewers when
publication should require a second approval.

### Repository Ruleset

In repository Settings > Rules > Rulesets, configure the `main` ruleset to require pull requests and
every Gate 2 CI job listed above.

## Recovering from a Bad Tag

Before deleting or replacing any tag, verify that RubyGems publication never occurred. Check the
release workflow and the version list on RubyGems. If RubyGems accepted the version, do not delete,
move, or reuse its tag; fix the problem through a new patch release.

Only when the workflow never published the gem may you remove the tag, correct the release through
a pull request, and tag the corrected commit after all gates pass again:

```bash
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z
```

If release metadata is wrong on `main`, open another pull request. Do not amend or force-push
protected branch history.
