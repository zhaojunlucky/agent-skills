---
name: gh-issue
description: Use when an AI assistant needs to inspect, summarize, triage, or analyze GitHub issues using the GitHub CLI `gh`, including issue metadata, comments, labels, linked pull requests, and timeline context.
---

# GitHub Issue

Use the GitHub CLI (`gh`) as the primary source for live GitHub issue data. This skill is read-only by default and is written for any assistant or LLM that can run shell commands.

## Core Workflow

1. Confirm repository context.
   - If the current directory may be inside the target repository, run `gh repo view --json owner,name,url`.
   - If the user provided an explicit owner/repo, pass `--repo OWNER/REPO` to `gh` commands.
   - If repository context is missing or ambiguous, ask for the repository before making claims.

2. Identify the issue.
   - If the user provides an issue number or URL, use it directly.
   - If no issue is provided, use `gh issue list` and select only when the user intent is clear.
   - Treat GitHub issues and pull requests carefully: both use issue numbers, but PRs include pull request fields.

3. Retrieve issue context.
   - Get title, body, state, author, labels, assignees, milestone, timestamps, comments, and URL.
   - Fetch comments when the user asks for discussion, requirements, decisions, reproduction steps, or current status.
   - Fetch timeline/events when lifecycle details matter, such as assignment, labeling, closure, reopening, linking, or cross-references.

4. Retrieve linked pull requests when relevant.
   - Inspect issue body and comments for PR references.
   - Use timeline/events or GraphQL when cross-references or closing PRs are needed.
   - If analyzing whether an issue is fixed, inspect the linked PRs with the pull request workflow.

5. Report facts first, then analysis.
   - Clearly separate observed GitHub data from conclusions, recommendations, or triage decisions.
   - Include the commands used when useful for reproducibility.

## Useful Commands

Repository context:

```sh
gh repo view --json owner,name,url
```

Find issues:

```sh
gh issue list --limit 20
gh issue list --state open --json number,title,state,author,labels,assignees,updatedAt,url
gh issue list --label LABEL --limit 20
gh issue list --search "SEARCH TERMS" --limit 20
```

Issue metadata:

```sh
gh issue view ISSUE --json number,title,body,state,author,labels,assignees,milestone,comments,createdAt,updatedAt,closedAt,url
gh issue view ISSUE --comments
```

REST API fallback:

```sh
gh api repos/OWNER/REPO/issues/ISSUE
gh api repos/OWNER/REPO/issues/ISSUE/comments
gh api repos/OWNER/REPO/issues/ISSUE/events
gh api repos/OWNER/REPO/issues/ISSUE/timeline
```

Add `--repo OWNER/REPO` to `gh issue` commands when the target repository is not the current directory.

## Linked Pull Requests

When issue analysis depends on linked PRs:

- Inspect the issue body and comments for PR references such as `#123`, `REPO#123`, and `OWNER/REPO#123`.
- Inspect issue events or timeline for cross-referenced PRs, closure events, or reopening events.
- For closing PRs, fetch the PR metadata and diff before claiming the issue is fixed.

Example GraphQL query shape for closing PRs when REST output is insufficient:

```sh
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    issue(number:$number) {
      closingIssuesReferences(first:20) {
        nodes { number title url state }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=ISSUE
```

## Output Format

For an issue summary, include:

- Repository
- Issue number, title, author, state, and URL
- Labels, assignees, milestone, and timestamps when available
- Key requirements, reproduction steps, acceptance criteria, or decisions from the body and comments
- Linked PRs or cross-references when relevant

For triage or analysis, include:

- Current status and evidence
- Missing information or blockers
- Related PRs, commits, or issues inspected
- Concrete next step

## Safety

- Treat inspection commands as read-only.
- Do not invent data for private repositories, missing issues, or inaccessible comments.
- If `gh` is unauthenticated or lacks access, state that GitHub CLI authentication or repository permission is required.
- Commands that change GitHub state require explicit user confirmation before running. This includes commenting, editing title/body, closing, reopening, assigning, labeling, milestoning, locking, transferring, and converting issues.
