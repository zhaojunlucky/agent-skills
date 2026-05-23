---
name: gh-workflow-run
description: Use when an AI assistant needs to inspect, debug, summarize, compare, or retrieve GitHub Actions workflow run data using the GitHub CLI `gh`.
---

# GitHub Workflow Run

Use the GitHub CLI (`gh`) as the primary source for live GitHub Actions workflow run data. This skill is read-only by default and is written for any assistant or LLM that can run shell commands.

## Core Workflow

1. Confirm repository context.
   - If the current directory may be inside the target repository, run `gh repo view --json owner,name,url`.
   - If the user provided an explicit owner/repo, pass `--repo OWNER/REPO` to `gh` commands.
   - If repository context is missing or ambiguous, ask for the repository before making claims.

2. Identify the run.
   - If the user provides a run ID or URL, use that run directly.
   - If no run ID is provided, list recent runs and filter by the available clues: workflow name, branch, event, actor, status, conclusion, commit, PR, or approximate time.
   - Prefer structured fields over terminal-only formatting when the command supports JSON.

3. Retrieve run and job data.
   - Use `gh run view` for run-level details.
   - Use `gh api` when job lists, timestamps, URLs, or fields missing from `gh run view` are needed.
   - Fetch logs only when the user asks for failure details, diagnosis, or evidence that requires log lines.

4. Summarize facts first, then inference.
   - Clearly distinguish observed GitHub data from likely causes or recommendations.
   - Include the commands used when useful for reproducibility.

## Useful Commands

Repository context:

```sh
gh repo view --json owner,name,url
```

Recent runs:

```sh
gh run list --limit 20
gh run list --workflow WORKFLOW_NAME --limit 20
gh run list --branch BRANCH --limit 20
gh run list --status failure --limit 20
```

Run details:

```sh
gh run view RUN_ID
gh run view RUN_ID --json databaseId,displayTitle,event,headBranch,headSha,name,number,status,conclusion,createdAt,startedAt,updatedAt,url,workflowName
```

Logs:

```sh
gh run view RUN_ID --log
gh run view RUN_ID --log-failed
```

REST API for complete run and job data:

```sh
gh api repos/OWNER/REPO/actions/runs/RUN_ID
gh api repos/OWNER/REPO/actions/runs/RUN_ID/jobs
```

Add `--repo OWNER/REPO` to `gh run` commands when the target repository is not the current directory.

## Failure Analysis

When diagnosing a failed run:

1. Get the run summary and job list.
2. Identify failed or cancelled jobs.
3. Inspect only the relevant failed-job logs unless the user requests broader log review.
4. Report the failing job, failing step, key error text, and the smallest useful context.
5. Avoid quoting long logs; summarize and include short excerpts only when they materially support the diagnosis.

## Output Format

For a run summary, include:

- Repository
- Workflow name
- Run ID and URL
- Status and conclusion
- Branch, commit SHA, event, and actor when available
- Start time, end/update time, and duration when available
- Failed jobs or skipped jobs when relevant

For a failure diagnosis, include:

- What failed
- Evidence from GitHub data or logs
- Likely cause, labeled as inference
- Concrete next step

## Safety

- Treat inspection commands as read-only.
- Do not invent data for private repositories, missing runs, or inaccessible logs.
- If `gh` is unauthenticated or lacks access, state that GitHub CLI authentication or repository permission is required.
- Commands that change GitHub state require explicit user confirmation before running. This includes reruns, cancellations, workflow dispatches, artifact deletion, and any API call using non-GET methods.
