# Releasing Reviewer

Reviewer releases have three gates: accept one exact commit from `origin/main`, prepare release
metadata through a pull request, then publish by pushing a version tag from the merged release
commit. A tag push starts publication and must not happen until the first two gates are complete.

## Gate 1: Accept the Candidate

Fetch `main`, fast-forward the local checkout, and record the candidate commit:

```bash
git fetch origin main
test -z "$(git status --porcelain)" || {
  echo "Working directory has uncommitted changes" >&2
  exit 1
}
git switch main
git merge --ff-only origin/main
candidate_sha=$(git rev-parse HEAD)
test "$candidate_sha" = "$(git rev-parse origin/main)"
test -z "$(git status --porcelain)"
bundle check
```

The worktree must be clean, and `candidate_sha` must equal `origin/main`. Verify that exact commit
before changing the version. Replace the test paths for releases covering different behavior:

```bash
bundle exec ruby -Itest test/reviewer/file_scoped_cli_test.rb
bundle exec ruby -Itest test/release_test.rb
bundle exec rake release:dry_run
```

For Reviewer 1.1.1, the file-scoped CLI test is the candidate smoke test. It runs the checkout's
`exe/rvw` in a temporary Git project and proves that bare runs still execute broad tools, explicit
and Git-derived scopes skip tools without file support, file-aware tools receive only the resolved
files, failed retries retain their scope, and JSON reports the skipped state and count.

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
3. If gem metadata or packaging is defective, stop and correct it through a focused pull request,
   then accept a new candidate. Do not expand the release preparation pull request.
4. Leave a new empty `[Unreleased]` section in `CHANGELOG.md` and move the accepted changes into a
   dated `[X.Y.Z] - YYYY-MM-DD` section.
5. Put compatibility and upgrade notes before the feature and fix lists.
6. Update this guide when the release workflow itself changes.

Preview the versioned package and run Reviewer against the staged release changes:

```bash
bundle exec rake release:dry_run
RELEASE_TAG=vX.Y.Z bundle exec rake release:notes
git add lib/reviewer/version.rb Gemfile.lock CHANGELOG.md RELEASING.md
staged_paths=$(git diff --cached --name-only) || exit
required_paths=$(printf '%s\n' CHANGELOG.md Gemfile.lock lib/reviewer/version.rb)
with_guide_paths=$(printf '%s\n' CHANGELOG.md Gemfile.lock RELEASING.md lib/reviewer/version.rb)
if test "$staged_paths" != "$required_paths" && test "$staged_paths" != "$with_guide_paths"; then
  echo "Unexpected staged paths:" >&2
  printf '%s\n' "$staged_paths" >&2
  exit 1
fi
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
test -z "$(git status --porcelain)" || {
  echo "Working directory has uncommitted changes" >&2
  exit 1
}
git switch main
git pull --ff-only
test -z "$(git status --porcelain)"
```

Run the full preflight and preview the final package:

```bash
bundle exec rake release:preflight
bundle exec rake release:dry_run
RELEASE_TAG=vX.Y.Z bundle exec rake release:notes
```

`release:preflight` runs the full tests, dependency audit, and `release:check`. It belongs here
because `release:check` requires the current branch to be `main`. This is a release-manager step;
agents restricted to focused tests must stop and hand it to the maintainer.

Before tagging, confirm all of the following for the checked-out commit:

- `Reviewer::VERSION` matches the intended tag.
- `CHANGELOG.md` has a dated and complete section for the version.
- `HEAD` equals `origin/main` and the required CI jobs passed for that exact commit.
- RubyGems does not already contain the version.
- The version tag does not exist locally or remotely.

Verify the exact `main` push run rather than relying on a pull-request or branch-level green state:

```bash
release_sha=$(git rev-parse HEAD)
ci_run=$(
  gh run list --workflow main.yml --commit "$release_sha" --event push --limit 100 \
    --json databaseId,headSha,createdAt,attempt,status,conclusion |
    jq -er --arg sha "$release_sha" '
      map(select(.headSha == $sha)) |
      sort_by(.createdAt, .attempt) |
      last |
      select(.status == "completed" and .conclusion == "success") |
      .databaseId
    '
)

gh run view "$ci_run" --json headSha,status,conclusion,jobs |
  jq -e --arg sha "$release_sha" '
    .headSha == $sha and .status == "completed" and .conclusion == "success" and
    ([.jobs[] | select(.status == "completed" and .conclusion == "success") | .name]) as $passed |
    ["Security", "Changelog", "Version",
     "Test (Ruby 3.2)", "Test (Ruby 3.3)",
     "Test (Ruby 3.4)", "Test (Ruby 4.0)"] |
    all(.[]; . as $job | $passed | index($job) != null)
  '
```

Both commands must exit zero, and the final predicate must print `true`. A missing, pending,
cancelled, or failed job stops the release.

Prove that the version and tag are unused. These checks fail closed: an unexpected command status,
network failure, HTTP error, or malformed response stops the release rather than counting as
absence.

```bash
tag=vX.Y.Z
version=${tag#v}

if git show-ref --verify --quiet "refs/tags/$tag"; then
  echo "Local tag already exists: $tag" >&2
  exit 1
else
  check_status=$?
  test "$check_status" -eq 1 || exit "$check_status"
fi

if git ls-remote --exit-code --refs --tags origin "refs/tags/$tag" >/dev/null; then
  echo "Remote tag already exists: $tag" >&2
  exit 1
else
  check_status=$?
  test "$check_status" -eq 2 || exit "$check_status"
fi

ruby -rnet/http -rjson -ruri - "$version" <<'RUBY'
version = ARGV.fetch(0)
uri = URI('https://rubygems.org/api/v1/versions/reviewer.json')
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                          open_timeout: 10, read_timeout: 10) { |http| http.get(uri.request_uri) }
abort "RubyGems lookup failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

versions = JSON.parse(response.body)
valid = versions.is_a?(Array) && !versions.empty? && versions.all? do |entry|
  entry.is_a?(Hash) && entry['number'].is_a?(String) && !entry['number'].empty?
end
abort 'RubyGems lookup failed: unexpected response' unless valid
abort "RubyGems version already exists: #{version}" if versions.any? { |entry| entry['number'] == version }

puts "RubyGems version is available: #{version}"
RUBY
```

Immediately before tag authorization, the maintainer verifies that RubyGems trusted publishing is
configured for repository `garrettdimon/reviewer`, workflow `.github/workflows/release.yml`, and
environment `rubygems`. If the settings cannot be verified or differ, stop before tagging; changing
external publishing configuration requires separate authorization.

Pushing the tag triggers `.github/workflows/release.yml`, which publishes the gem and then creates
the GitHub Release. Treat the tag push as the irreversible publication trigger and require explicit
authorization immediately before running it:

```bash
git fetch origin main
release_sha=$(git rev-parse HEAD)
test "$release_sha" = "$(git rev-parse origin/main)"
test -z "$(git status --porcelain)"
git tag "$tag" "$release_sha"
tag_ref_sha=$(git rev-parse "refs/tags/$tag")
tag_target_sha=$(git rev-parse "refs/tags/$tag^{}")
git push origin "refs/tags/$tag:refs/tags/$tag"
```

Record `release_sha`, `tag_ref_sha`, and `tag_target_sha` with the release evidence. Existing modern
Reviewer releases use lightweight tags; recording both identities also makes recovery safe if an
annotated tag is ever used.

The workflow independently rejects a tag that does not match `Reviewer::VERSION` or lacks a dated,
nonempty changelog section. The same validated section becomes the GitHub Release notes.

Never move or reuse a version tag after RubyGems has accepted that version.

## Verify the Published Artifact

Require all three publication results:

1. The [GitHub Actions `Release` workflow](https://github.com/garrettdimon/reviewer/actions/workflows/release.yml)
   succeeds.
2. [RubyGems](https://rubygems.org/gems/reviewer) lists the new Reviewer version.
3. [GitHub Releases](https://github.com/garrettdimon/reviewer/releases) contains the matching tag and
   changelog excerpt.

Install the public gem into a fresh temporary gem home so a same-version local build or cached gem
cannot satisfy the check. Run the smoke test from its own temporary project so it cannot load the
release checkout's configuration:

```bash
smoke_root=$(mktemp -d)
trap 'rm -rf -- "$smoke_root"' EXIT HUP INT TERM
published_gem_home="$smoke_root/gems"
smoke_project="$smoke_root/project"
mkdir -p "$published_gem_home" "$smoke_project"

GEM_HOME="$published_gem_home" GEM_PATH="$published_gem_home" \
  gem install reviewer -v X.Y.Z --no-document --clear-sources --source https://rubygems.org

test "$(GEM_HOME="$published_gem_home" GEM_PATH="$published_gem_home" \
  "$published_gem_home/bin/rvw" --version)" = "X.Y.Z"

cat > "$smoke_project/.reviewer.yml" <<'YAML'
broad:
  name: Broad
  commands:
    review: "ruby -e 'File.write(%q[broad-ran], %q[yes])'"
file_aware:
  name: File Aware
  commands:
    review: ruby record_invocation.rb
  files:
    review: ruby record_invocation.rb
    flag: ""
    separator: " "
    pattern: "*.rb"
YAML

cat > "$smoke_project/record_invocation.rb" <<'RUBY'
require 'json'
File.write('files.json', JSON.generate(ARGV))
RUBY
touch "$smoke_project/target.rb"

(
  cd "$smoke_project"
  GEM_HOME="$published_gem_home" GEM_PATH="$published_gem_home" \
    "$published_gem_home/bin/rvw" -f target.rb --json > result.json
)

ruby -rjson - "$smoke_project" <<'RUBY'
project = ARGV.fetch(0)
payload = JSON.parse(File.read(File.join(project, 'result.json')))
tools = payload.fetch('tools').to_h { |tool| [tool.fetch('tool'), tool] }

abort 'Review did not succeed' unless payload['success']
abort 'File-aware tool did not pass' unless tools.dig('file_aware', 'state') == 'passed'
abort 'Broad tool was not skipped' unless tools.dig('broad', 'state') == 'skipped'
abort 'Unexpected skipped count' unless payload.dig('summary', 'skipped') == 1
abort 'Wrong file arguments' unless JSON.parse(File.read(File.join(project, 'files.json'))) == ['target.rb']
abort 'Broad tool executed' if File.exist?(File.join(project, 'broad-ran'))
RUBY
```

The published artifact must reproduce the accepted candidate's result. Cleanup runs after success
or failure.

## Versioning Policy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (`X.0.0`): incompatible public API or configuration changes
- **MINOR** (`X.Y.0`): backward-compatible features and deprecations
- **PATCH** (`X.Y.Z`): backward-compatible fixes

Dropping Ruby support, removing public APIs, or changing default configuration behavior
incompatibly requires a major release.

## One-Time Publishing Setup

### RubyGems Trusted Publishing

1. Open [Reviewer's trusted publishers](https://rubygems.org/gems/reviewer/trusted_publishers).
2. Create a publisher for the existing gem with these values:
   - **Repository owner:** `garrettdimon`
   - **Repository name:** `reviewer`
   - **Workflow filename:** `release.yml`
   - **Environment:** `rubygems`
   - **Workflow repository owner and name:** leave both blank

### GitHub Environment

In the repository settings, create an environment named `rubygems`. Add required reviewers when
publication should require a second approval.

### Repository Ruleset

In repository Settings > Rules > Rulesets, configure the `main` ruleset to require pull requests and
every Gate 2 CI job listed above.

## Recovering from a Bad Tag

Before deleting or replacing any tag, verify that RubyGems publication never occurred. If the
triggered Release workflow is queued or running, [cancel it](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/cancel-a-workflow-run)
and wait until the run reaches a terminal state. Deleting the tag does not stop a workflow that has
already started. Recheck the version list on RubyGems after the workflow stops.

If RubyGems accepted the version, do not delete, move, or reuse its tag; fix the problem through a
new patch release.

Only when the workflow never published the gem may you consider removing the tag. Before deletion,
query the exact remote ref and require its ref object and peeled commit to match the values recorded
when the tag was pushed. A missing ref, lookup failure, or identity mismatch stops recovery:

```bash
remote_refs=$(git ls-remote --tags origin "refs/tags/$tag" "refs/tags/$tag^{}")
remote_ref_sha=$(printf '%s\n' "$remote_refs" | awk -v ref="refs/tags/$tag" '$2 == ref { print $1 }')
remote_target_sha=$(printf '%s\n' "$remote_refs" | awk -v ref="refs/tags/$tag^{}" '$2 == ref { print $1 }')
test -n "$remote_ref_sha"
test -n "$remote_target_sha" || remote_target_sha=$remote_ref_sha
test "$remote_ref_sha" = "$tag_ref_sha"
test "$remote_target_sha" = "$tag_target_sha"
```

Obtain explicit maintainer authorization immediately before deletion. Delete the remote tag with an
identity lease, confirm the exact remote ref is absent with the fail-closed check above, then delete
the local tag:

```bash
git push --force-with-lease="refs/tags/$tag:$tag_ref_sha" origin ":refs/tags/$tag"
git tag -d "$tag"
```

Correct the problem through a pull request and repeat every release gate. If release metadata is
wrong on `main`, do not amend or force-push protected branch history.
