---
name: pr-guidelines
description: House style for writing pull request titles and descriptions (which also serve as the squash-merge commit message). MUST be consulted before writing or finalizing any PR title/body, opening a PR (e.g. via git/gh pr create), or drafting a merge commit message — whether initiated by the user or by an agent working autonomously. Also applies when revising an existing PR description or reviewing one for style compliance.
---

# PR Guidelines

Write one description that serves as both the PR body and the squash-merge commit message.

## Title

- Sentence case: "Add API to get today's newspaper" (not `feat(mobile): add reading list...`).
- Prefixes are OK to shorten the title, as long as sentence case is kept: "Fix: favicon URL is used as feed's site URL".

## Description

### Write for the reader, not the author

Consolidate the messy commit history (`install`, `fix`, `style`, `rename`, `cleanup`, WIP merges) into one coherent prose description of what actually changed. Don't narrate the path taken to get there.

- Bad: "This PR started as a Patrol spike and ended up replacing a bunch of stuff. See commits for details."
- Good: "Replace the Flutter integration_test harness and external Prism mock server with Patrol and in-process HTTP mocking."

### Focus on behavior, not implementation

Describe what changed and why, at the level of behavior and intent. Skip class names, method signatures, provider wiring, file-by-file walkthroughs — the diff already shows those. (Exception: if the change *is* the implementation, e.g. a refactor, implementation detail becomes the point.)

- Bad: "Each test reads Dio from the Riverpod container and attaches a DioAdapter."
- Good: "Tests no longer depend on a separately-launched mock process."

This applies to the title too:
- Bad: `Add DioAdapter and remove app_harness.dart`
- Good: `Rework integration tests with Patrol and in-process HTTP mocking`

### Omit what the diff, README, and structure already show

Don't restate directory layout, naming conventions, or added keys if they're obvious from opening the changed files. Redundant description buries the parts that aren't obvious.

- Bad: "Adds `today_test.dart` and `feeds_test.dart`, a `helpers.dart` with `pumpApp`/`httpMockAdapter`, and `debug_keys.dart` defining `feedRow`, `entryRow`, `storyCard`… (see README for the full key list)."
- Good: (nothing — let the files and README speak for themselves)

### Lead with the headline, prefer real outcomes

Open with a one-sentence summary. Describe the *outcome* a change enables, not the mechanism.

- Bad: "Each test reads the live Dio from the Riverpod container and attaches a DioAdapter with a FullHttpRequestMatcher, enqueuing replies per route."
- Good: "Because mocking is now stateful, tests can assert on real outcomes: the subscribe test verifies the feed actually appears in the list, not just that a confirmation snackbar showed."

### Call out non-obvious side effects and tradeoffs

Surface anything a reviewer should consciously sign off on, especially outside the change's stated scope: a dependency downgrade, a dropped code path, a pinned pre-release, a temporary workaround. Put these in a dedicated `## Notes` section at the end, one bullet per item — keep them out of the main narrative.

```markdown
## Notes

- The mocking library constrains Dio, downgrading it from 5.10.0 to 5.9.2, which drops the transformTimeout error branch.
- patrol is pinned to a dev release for Swift Package Manager support.
```

## Formatting

- Prose paragraphs, not bullet-dumps of every file touched.
- No hard-wrapping — GitHub soft-wraps Markdown. One paragraph = one line.
- Keep it short: a few tight paragraphs beat an exhaustive changelog.

## Checklist before submitting

1. Title is sentence case, describes behavior not implementation.
2. Opens with a one-sentence outcome-focused summary.
3. Body describes behavior/intent, not code mechanics.
4. Nothing restated that's already obvious from the diff/README.
5. Side effects and tradeoffs (dependency changes, dropped paths, workarounds) are isolated in a `## Notes` section.
6. No hard-wrapped lines; no per-file bullet dump.
