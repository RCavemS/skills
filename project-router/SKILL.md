---
name: project-router
description: Picks the simplest, cheapest route that performs well for a new project or task, using a lean default stack (Claude Team for work, Gemini via Google AI Pro for personal) and adding a free-tier tool only when there's a measured reason. Outputs a short Route Card with account, repo, tools and first actions. Use this whenever the user describes a project, feature, idea or task they want to start ("I want to build...", "new project:", "let's do X"), asks which tool or account to use, or hits a usage limit, even if they don't say "route".
---

# Project Router

Turn a one-line project description into the simplest route that works.

## Principles (in this order)

1. **Governance:** the right account for the right code, always.
2. **Performance:** use the tool that does the job well.
3. **Simplicity:** use the fewest tools possible. One tool per project is the goal.
4. **Cost:** use what's already paid for before adding anything.

Add a tool only when there's evidence it's needed, never "just in case".

## Step 1: Classify (infer first, ask at most 1 question)

- **Owner:** work · personal · unclear. If unclear, ask.
- **Sensitivity:** normal · confidential (client data, secrets, PII)
- **Size:** spike (hours) · project (days or more)

## Step 2: Hard rules

1. Work: Claude Team account and work GitHub only.
2. Personal: Google AI Pro account and personal GitHub only. Never put personal code into the work Claude account. If this router runs there for a personal project, give the Route Card and stop.
3. Confidential data never goes to free tiers.
4. Agents propose and humans merge. Branch protection stays on.

## Step 3: Default stack (use this unless an add-on trigger fires)

| | Work | Personal |
|---|---|---|
| Plan, build, debug | Claude (Claude Code if the seat includes it) | Gemini: app for planning, Gemini CLI for building |
| Tasks | GitHub Issues | GitHub Issues |
| Review | CI plus you | CI plus you |

That's it: one AI tool per side, plus GitHub.

## Step 4: Add-ons (only when the trigger is real)

| Trigger | Add | Cost |
|---|---|---|
| Gemini CLI repeatedly fails on a hard task, or you want an IDE agent | Cursor Hobby (free) for that task only | Free |
| You want an automatic second reviewer on PRs | Gemini Code Assist GitHub app (personal repos) | Free, no upkeep |
| Many small, independent issues piling up | Jules for a batch | Included in AI Pro |

Before adding one, name the trigger in the Route Card. If no trigger fires, add nothing.

## Step 5: Output a Route Card

```
ROUTE CARD — <project>
Classification: <owner> · <sensitivity> · <size>
Account: <Claude Team | Google AI Pro>
Repo: <work-org | personal>/<name>
Tool: <one tool>  (+ add-on: <tool> because <trigger>, if any)
First 3 actions:
  1. ...
  2. ...
  3. ...
Watch-outs: <data, limits, policy>
```

For a spike, skip the repo setup and go straight to the tool.

## Step 6: New-repo setup (project size only)

- Create the repo from your template.
- Add the skills submodule: `git submodule add <skills-repo-url> .skills`
- Fill in `AGENTS.md` (stack, conventions, test command).
- Make sure `.gitignore`, `.geminiignore` and `.cursorignore` cover `.env` and secrets.
- Turn on branch protection with required CI.

## Step 7: Review the stack, not just the code

Once a month, ask: did any tool cause friction, or did a default fail often enough to justify an add-on, or a paid plan? Remove add-ons that weren't used. A subscription is justified only when a free tier is a repeated, measured bottleneck.

## Examples

**"Personal: habit tracker app, I have Figma screenshots."**
Personal · normal · project. Gemini only: plan in the app with the screenshots, build with Gemini CLI. No add-ons.

**"Automate our team's weekly report from Jira exports."**
Work · confidential · project. Claude only, in the work repo.

**"Quick script to rename my photos by date."**
Personal · normal · spike. Gemini CLI, no repo needed.
