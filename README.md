# agent-skills

This repository stores reusable agent skills.

## Link Skills Locally

Run the setup script to link every skill in this repo into `~/.agents/skills/`:

```sh
./scripts/setup-hook.sh
```

The script creates one symlink per skill:

```text
~/.agents/skills/<skill-name> -> <repo>/skills/<skill-name>
```

It records links it manages in:

```text
~/.agents/.veda-agent-skill
```

On later runs, the script removes managed links for skills that no longer exist in
this repo. It does not overwrite existing real files or directories in
`~/.agents/skills/`. If a target already exists and was not previously managed by
this repo, the script reports a conflict and leaves it unchanged.

## Install Git Hooks

Install repo-local Git hooks so skill links refresh after common `git pull`
flows:

```sh
./scripts/install-hooks.sh
```

This installs managed `.git/hooks/post-merge` and `.git/hooks/post-rewrite`
hooks. The hooks run `./scripts/setup-hook.sh` after merge-based pulls and
rebase-based pulls.

If a hook already exists and is not managed by this repo, the installer skips it
instead of overwriting it.

## Add a Skill

Create one directory per skill under `skills/`:

```text
skills/<skill-name>/
  SKILL.md
  agents/openai.yaml
```

`SKILL.md` is required. `agents/openai.yaml` is recommended for UI metadata.

## SKILL.md

Start each skill with YAML frontmatter:

```markdown
---
name: example-skill
description: Use when an AI assistant needs to do a specific task.
---

# Example Skill

Write concise instructions that tell the assistant when to use the skill,
what commands or tools to prefer, what workflow to follow, and how to report
results.
```

Guidelines:

- Keep the skill focused on one capability.
- Write instructions for any assistant or LLM unless the skill is intentionally model-specific.
- Include only context the assistant needs at run time.
- Prefer concrete workflows and command examples over broad explanations.
- Put large references, scripts, or assets in separate folders only when they are directly useful.
- Do not add extra documentation files such as `README.md` or `CHANGELOG.md` inside a skill directory.

## agents/openai.yaml

Use `agents/openai.yaml` for optional interface metadata:

```yaml
interface:
  display_name: "Example Skill"
  short_description: "Do a specific task"
  default_prompt: "Use $example-skill to do the specific task."
```

Rules:

- Quote all string values.
- Keep `short_description` brief.
- Mention the skill name in `default_prompt` using `$skill-name`.

## Validate

Before committing a new skill:

1. Confirm the directory is under `skills/<skill-name>/`.
2. Confirm `SKILL.md` has valid YAML frontmatter with `name` and `description`.
3. Confirm `agents/openai.yaml` parses if present.
4. Check that the skill is concise and does not duplicate generic documentation.

Example YAML validation:

```sh
ruby -e 'require "yaml"; YAML.load_file("skills/example-skill/agents/openai.yaml")'
```
