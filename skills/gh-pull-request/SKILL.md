---
name: gh-pull-request
description: Use when an AI assistant needs to inspect a GitHub pull request with `gh`, including PR metadata, changed files, diffs, patches, linked issues, and full base/head file context.
---

# GitHub Pull Request

Use the GitHub CLI (`gh`) and local `git` commands as the primary sources for pull request data. This skill is read-only by default and is written for any assistant or LLM that can run shell commands.

## Core Workflow

1. Confirm repository context.
   - If the current directory may be inside the target repository, run `gh repo view --json owner,name,url`.
   - If the user provided an explicit owner/repo, pass `--repo OWNER/REPO` to `gh` commands.
   - If repository context is missing or ambiguous, ask for the repository before making claims.

2. Identify the pull request.
   - If the user provides a PR number or URL, use it directly.
   - If no PR is provided, use `gh pr status` or `gh pr list` and select only when the user intent is clear.
   - Prefer structured JSON fields for metadata and file lists.

3. Get PR metadata and changed files.
   - Retrieve title, author, state, base/head refs, commits, URL, review state, and mergeability when relevant.
   - Retrieve the changed file list with status, additions, deletions, and paths.

4. Get the diff.
   - Use `gh pr diff PR` for the complete PR diff.
   - Use `gh pr diff PR --patch` when patch format is needed.
   - Use `git diff BASE...HEAD -- PATH` after fetching refs when focused per-file diffs or local tooling are needed.

5. Get full file context.
   - Do not rely only on patch hunks when the task requires understanding behavior, reviewing code, or explaining impact.
   - Fetch base and head refs, then read full files from both sides with `git show`.
   - For renamed files, inspect both the previous and current path when useful.

6. Get linked issue context.
   - Inspect the PR body for GitHub closing keywords and issue references.
   - Fetch each referenced issue before reviewing whether the PR satisfies the issue requirements.
   - Include issue context in the analysis when the PR claims to close or fix an issue.

7. Report facts first, then analysis.
   - Clearly separate observed PR data from conclusions or recommendations.
   - Include the commands used when useful for reproducibility.

## Useful Commands

Repository context:

```sh
gh repo view --json owner,name,url
```

Find pull requests:

```sh
gh pr status
gh pr list --limit 20
gh pr list --state open --json number,title,author,headRefName,baseRefName,updatedAt,url
```

PR metadata:

```sh
gh pr view PR --json number,title,body,state,author,baseRefName,headRefName,headRepository,headRepositoryOwner,commits,files,additions,deletions,changedFiles,mergeable,reviewDecision,url
```

Diffs:

```sh
gh pr diff PR
gh pr diff PR --patch
```

Fetch PR refs for local inspection:

```sh
gh pr checkout PR
git fetch origin pull/PR/head:pr-PR
```

Use `gh pr checkout PR` when it is acceptable to change the working tree branch. Use `git fetch` when the assistant should avoid switching branches.

Full base/head file context after fetching refs:

```sh
git show BASE_REF:path/to/file
git show HEAD_REF:path/to/file
```

Focused local diffs:

```sh
git diff BASE_REF...HEAD_REF -- path/to/file
git diff --name-status BASE_REF...HEAD_REF
```

REST API fallback for files and patches:

```sh
gh api repos/OWNER/REPO/pulls/PR/files
gh api repos/OWNER/REPO/pulls/PR
```

Add `--repo OWNER/REPO` to `gh pr` commands when the target repository is not the current directory.

## Linked Issues

When reviewing a PR, inspect the PR body for GitHub closing keywords:

- `close`, `closes`, `closed`
- `fix`, `fixes`, `fixed`
- `resolve`, `resolves`, `resolved`

Parse linked issue references in these forms:

- `KEYWORD #ISSUE`
- `KEYWORD REPO#ISSUE`
- `KEYWORD OWNER/REPO#ISSUE`

Use the PR repository for `#ISSUE`. For `REPO#ISSUE`, infer the owner from the PR repository owner, then verify the issue exists. For `OWNER/REPO#ISSUE`, use that exact repository.

Fetch issue context:

```sh
gh issue view ISSUE --repo OWNER/REPO --json number,title,body,state,author,labels,assignees,milestone,comments,createdAt,updatedAt,closedAt,url
gh issue view ISSUE --repo OWNER/REPO --comments
```

When reporting review findings, include whether the PR appears to satisfy the linked issue requirements. Clearly separate issue requirements from PR changes and call out mismatches, missing acceptance criteria, or behavior that is not covered by the PR.

## Full File Context Guidance

When full context is requested, collect:

- The PR diff or patch.
- The list of changed files and their statuses.
- Linked issue context from closing keywords in the PR body.
- The full head version of each changed text file.
- The full base version when comparing behavior, reviewing deletions, detecting regressions, or understanding renamed files.
- Nearby tests, config, or call sites when the changed file depends on them and local context is available.

Skip or summarize generated files, lockfiles, vendored files, minified assets, binary files, and very large files unless the user explicitly asks for them.

## Output Format

For a PR summary, include:

- Repository
- PR number, title, author, state, and URL
- Base and head refs
- Changed file count, additions, and deletions
- Linked issues and their state when present
- File list grouped by status when helpful
- Important metadata such as mergeability or review decision when relevant

For a review or analysis, include:

- The exact files or diffs inspected
- The linked issues inspected, if any
- Findings grounded in file paths, lines, or concise evidence
- Any assumptions or missing context
- Concrete next steps

## Safety

- Treat inspection commands as read-only.
- Do not invent data for private repositories, missing PRs, or inaccessible files.
- If `gh` is unauthenticated or lacks access, state that GitHub CLI authentication or repository permission is required.
- Avoid changing the user's working tree unless needed. Prefer `gh pr view`, `gh pr diff`, `gh api`, and `git fetch` over `gh pr checkout`.
- Commands that change GitHub state require explicit user confirmation before running. This includes creating comments, requesting reviews, approving, merging, closing, reopening, editing labels, and pushing commits.
