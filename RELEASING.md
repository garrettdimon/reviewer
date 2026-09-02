# Releasing Reviewer

Reviewer is released from a verified `main` commit. A version tag starts publication, so merging a
release pull request and pushing its tag are separate maintainer decisions.

Use `X.Y.Z` below for the intended version and `vX.Y.Z` for its tag. Record the accepted commit,
commands, and results with the release pull request.

## 1. Accept a Candidate

Start from a clean checkout and fast-forward `main`:

```bash
test -z "$(git status --porcelain)" &&
  git fetch origin main &&
  git switch main &&
  git merge --ff-only origin/main &&
  test -z "$(git status --porcelain)" &&
  candidate_sha=$(git rev-parse HEAD) &&
  test "$candidate_sha" = "$(git rev-parse origin/main)" &&
  bundle check
```

Run the focused tests for the changes being released, then validate the release machinery and
package:

```bash
bundle exec ruby -Itest test/release_test.rb
bundle exec rake release:dry_run
```

If validation fails, fix the defect through a separate pull request. If `origin/main` advances,
restart candidate acceptance from its new tip.

## 2. Prepare the Release Pull Request

Create the release branch from the accepted commit:

```bash
git switch -c release/X.Y.Z "$candidate_sha"
```

Change only the release metadata:

1. Set `Reviewer::VERSION` in `lib/reviewer/version.rb`.
2. Refresh `Gemfile.lock` so its local `reviewer` specification has the same version.
3. Leave an empty `[Unreleased]` section in `CHANGELOG.md` and add a dated release section.
4. Include upgrade instructions only when users must take action.

Do not include runtime fixes, release infrastructure, or unrelated documentation. Change this guide
only when the reusable release process itself changes, preferably in a separate pull request.

Validate and stage the release metadata:

```bash
bundle exec rake release:dry_run
RELEASE_TAG=vX.Y.Z bundle exec rake release:notes
git add lib/reviewer/version.rb Gemfile.lock CHANGELOG.md
bundle exec rvw staged
```

If the staged check changes files, re-stage them and rerun it. Commit and push the branch, then open
a pull request into `main`. Require every pull-request check to pass and resolve review findings.
Only the maintainer merges the release pull request.

## 3. Verify and Publish

After the release pull request is merged, update `main` and record the exact release commit:

```bash
test -z "$(git status --porcelain)"
git fetch origin main
git switch main
git merge --ff-only origin/main
test -z "$(git status --porcelain)"
release_sha=$(git rev-parse HEAD)
test "$release_sha" = "$(git rev-parse origin/main)"
```

Require a successful `main` workflow whose head SHA is exactly `release_sha`. Then run the
maintainer gates:

```bash
bundle exec rake release:preflight
bundle exec rake release:dry_run
RELEASE_TAG=vX.Y.Z bundle exec rake release:notes
```

Before tagging, confirm that:

- `Reviewer::VERSION` and the changelog match `vX.Y.Z`.
- RubyGems does not already contain version `X.Y.Z`.
- `vX.Y.Z` does not exist locally or on `origin`.
- RubyGems trusted publishing still targets this repository, `release.yml`, and the `rubygems`
  environment.

Immediately before publication, obtain explicit maintainer authorization. Fetch `origin/main` again
and create the tag only if the verified commit is still current:

```bash
(
set -euo pipefail
tag=vX.Y.Z
git fetch origin main
test "$(git rev-parse HEAD)" = "$release_sha"
test "$release_sha" = "$(git rev-parse origin/main)"
test -z "$(git status --porcelain)"
git tag "$tag" "$release_sha"
tag_ref_sha=$(git rev-parse "refs/tags/$tag")
tag_target_sha=$(git rev-parse "refs/tags/$tag^{}")
git push origin "refs/tags/$tag:refs/tags/$tag"
printf 'release=%s tag-ref=%s tag-target=%s\n' "$release_sha" "$tag_ref_sha" "$tag_target_sha"
)
```

Pushing the tag starts `.github/workflows/release.yml`, which publishes the gem and creates the
GitHub Release. Record the printed identities with the release evidence. Agents do not create or
push a release tag without explicit authorization.

## 4. Verify the Public Release

Require all of the following:

- The `Release` workflow succeeded for the version tag.
- RubyGems serves the intended version.
- The GitHub Release exists and contains the validated changelog notes.
- The gem installs into a fresh, isolated gem home and reports the intended version.
- A focused smoke test demonstrates the release's customer-facing behavior.

Record the public URLs and smoke-test result with the release evidence.

## Recovery

If publication fails, stop all tag changes and wait for the workflow to reach a terminal state.
Check RubyGems before taking corrective action.

- If RubyGems published the version, preserve the tag and prepare a new patch release.
- If RubyGems never published the version, remove the tag only with explicit maintainer
  authorization and only after confirming the local and remote tag identities match the failed
  release.
- Correct the problem through a pull request and repeat every release gate.

Never move or reuse a version tag that RubyGems accepted.

## Versioning

Follow [Semantic Versioning](https://semver.org/): use patch releases for backward-compatible fixes,
minor releases for backward-compatible features, and major releases for incompatible changes.

## One-Time Setup

- Configure RubyGems trusted publishing for `garrettdimon/reviewer`, workflow `release.yml`, and
  environment `rubygems`.
- Create the matching GitHub `rubygems` environment and configure any required reviewers.
- Protect `main` with pull requests and the repository's required CI checks.
