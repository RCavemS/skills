#!/usr/bin/env bash
# new-project.sh — create a new personal project repo, fully set up for the AI workflow.
#
# Usage:
#   ./new-project.sh <project-name> [--private] [--dry-run]
#
# Requires: git, GitHub CLI (gh) logged in with `gh auth login`.
# Creates: GitHub repo with AGENTS.md, GEMINI.md, Antigravity rule, ignores, CI, your skills as a
#          submodule in .skills/, and branch protection (public repos).

set -euo pipefail

NAME="${1:-}"
VISIBILITY="--public"
DRY_RUN=false
for arg in "${@:2}"; do
  case "$arg" in
    --private) VISIBILITY="--private" ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Usage: ./new-project.sh <project-name> [--private] [--dry-run]"
  exit 1
fi

if $DRY_RUN; then
  OWNER="your-username"
else
  command -v git >/dev/null || { echo "Install git first."; exit 1; }
  command -v gh  >/dev/null || { echo "Install GitHub CLI (gh) first."; exit 1; }
  gh auth status >/dev/null 2>&1 || { echo "Run: gh auth login"; exit 1; }
  OWNER="$(gh api user -q .login)"
fi

if [[ -e "$NAME" ]]; then
  echo "A folder named '$NAME' already exists here. Pick another name or location."
  exit 1
fi

echo "Creating $NAME for $OWNER..."
mkdir "$NAME" && cd "$NAME"
git init -q -b main

# ---------- AGENTS.md: the one instruction file every tool reads ----------
cat > AGENTS.md << 'EOF'
# AGENTS.md

Instructions for any AI agent working in this repo.

## Project
- What it is: <one sentence>
- Stack: <language, framework>
- Run tests: `<command>`
- Run locally: `<command>`

## Workflow rules
1. Every change starts from a GitHub Issue. Work on a branch named `issue-<number>-<short-name>`.
2. Never push to `main`. Open a pull request that references the issue ("Closes #<number>").
3. Run the tests before opening a PR. Add tests for new behavior.
4. Keep PRs small: one issue per PR.
5. Never read, print or commit `.env` files, keys or other secrets.
6. If something is unclear, ask instead of guessing.

## Skills
Reusable skills live in `.skills/`. Before starting a task, check whether a skill
there matches it (each skill's SKILL.md starts with a description of when to use it).
If one matches, read that SKILL.md and follow it.

## Conventions
- <add rules here whenever an agent makes the same mistake twice>
EOF

# ---------- GEMINI.md: points Gemini CLI at AGENTS.md ----------
cat > GEMINI.md << 'EOF'
Follow the instructions in AGENTS.md, imported below.

@./AGENTS.md
EOF

# ---------- Antigravity rule: points the Antigravity agent at AGENTS.md ----------
mkdir -p .agent/rules
cat > .agent/rules/agents.md << 'EOF'
Before any task, read AGENTS.md at the repository root and follow it.
EOF

# ---------- Ignore files ----------
cat > .gitignore << 'EOF'
# Secrets
.env
.env.*
!.env.example
*.pem
*.key

# Dependencies and builds
node_modules/
__pycache__/
.venv/
dist/
build/

# OS and editor
.DS_Store
Thumbs.db
.vscode/
.idea/
EOF

cat > .geminiignore << 'EOF'
.env
.env.*
*.pem
*.key
secrets/
data/private/
EOF
cp .geminiignore .cursorignore

# ---------- CI: runs tests on every PR ----------
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Node tests
        if: hashFiles('package.json') != ''
        run: |
          npm ci || npm install
          npm test --if-present

      - name: Python tests
        if: hashFiles('requirements.txt', 'pyproject.toml') != ''
        run: |
          pip install -r requirements.txt 2>/dev/null || pip install -e . 2>/dev/null || true
          pip install pytest
          pytest || [ $? -eq 5 ]   # exit code 5 = no tests yet, which is OK

      - name: Nothing to test yet
        if: hashFiles('package.json', 'requirements.txt', 'pyproject.toml') == ''
        run: echo "No package.json or Python project yet. CI passes."
EOF

# ---------- README ----------
cat > README.md << EOF
# $NAME

<What this project does, in one or two sentences.>

Built with the AI workflow: see AGENTS.md.
EOF

# ---------- Skills submodule ----------
if $DRY_RUN; then
  echo "[dry-run] would add https://github.com/$OWNER/skills.git as .skills"
else
  git submodule add -q "https://github.com/$OWNER/skills.git" .skills
fi

git add -A
git commit -q -m "Initial setup for AI workflow"

if $DRY_RUN; then
  echo "[dry-run] would create GitHub repo $OWNER/$NAME ($VISIBILITY) and push"
  echo "[dry-run] files created:"
  find . -path ./.git -prune -o -type f -print | sort
  exit 0
fi

# ---------- Create repo on GitHub and push ----------
gh repo create "$NAME" $VISIBILITY --source=. --push

# ---------- Branch protection: agents must go through PRs + CI ----------
if [[ "$VISIBILITY" == "--public" ]]; then
  gh api -X PUT "repos/$OWNER/$NAME/branches/main/protection" --silent --input - << 'EOF' \
    && echo "Branch protection on: main needs a PR with passing CI." \
    || echo "Couldn't set branch protection. Set it in Settings > Branches."
{
  "required_status_checks": { "strict": true, "contexts": ["check"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null
}
EOF
else
  echo "Private repo: branch protection needs a paid GitHub plan, so it was skipped."
  echo "Keep the PR-only rule in AGENTS.md as your safeguard."
fi

echo
echo "Done: https://github.com/$OWNER/$NAME"
echo "Next: in Antigravity, use File > Open Folder and open the $NAME folder,"
echo "then ask the agent to fill in the <placeholders> in AGENTS.md with you."
