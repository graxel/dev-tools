# dev-tools

Shared tools for projects.

| Tool | What it does | Why |
|---|---|---|
| `shell/newproject.zsh` | `newproject <name>`: create a new project | Easy way to set up a new project on a whim when inspiration strikes |
| `bin/git-preview` | `git preview`: publish uncommitted work to QA (mostly from `dev`) | Check the frontend on a phone before committing |
| `bin/git-ship` | `git ship`: `git push`, then publish (sync) the frontend | Allows serving both PROD and QA versions of website frontend on GH Pages|


## Typical project layout

Backend at the repo root, frontend in `website/`:

```
myproject/
├── .ship            FRONTEND_DIR=website
├── website/         PROD version of frontend files
|   └── qa/          QA version of frontend files
└── ...              Main project contents (mostly backend)
```

Branches: `dev` (DEV), `test` (QA), `main` (PROD), plus `gh-pages`, which only `git ship` writes to. I never have to touch `gh-pages`.

## git ship

Push the current branch, then publish the frontend to GitHub Pages.

| Branch | Pushes | Frontend published to |
|---|---|---|
| `main` | yes | `https://<mydomain>/<repo>/` |
| `test` | yes | `https://<mydomain>/<repo>/qa/` |
| anything else | yes | nothing |

### Preview uncommitted work

```
git preview
```

Publishes your **working files** to `https://kevingrazel.com/<repo>/qa/`, including uncommitted edits and new files (anything `.gitignore` excludes is skipped). It works on any branch **except `main`**, and it doesn't push or commit anything in your repo. Edit, preview, check on your phone, repeat; commit when you're happy.

`/qa/` shows whichever ran last: `git ship` on `test`, or `git preview`.

### Set up a project (once)

`newproject` does this automatically: it adds `.ship` with `FRONTEND_DIR=website` to the first commit and runs `git ship init`, so a new project shows a "coming soon" page until its first publish from `main`. Edit `.ship` later if the frontend lives elsewhere, e.g. `FRONTEND_DIR=app/frontend`.

For a repo made before `newproject` did this, add and commit that `.ship` file yourself. The first `git ship` from `main` or `test` then creates the `gh-pages` branch and turns on GitHub Pages by itself (or run `git ship init` to do that right away).

A repo without `.ship` has no frontend: `git ship` just pushes. If `.ship` exists but the folder doesn't yet, `git ship` pushes and says there's nothing to publish.

### Rules

- Prod (`main`) only ever gets **committed** code. Uncommitted work can only go to QA, via `git preview`.
- If the push fails, nothing is published.
- Re-running is always safe. Each publish starts fresh from GitHub's copy of `gh-pages`.
- Roll back with `git revert`, then `git ship`.

## newproject

```
newproject <name>
```

Checks everything first (valid name, folder and GitHub repo don't exist yet, `uv` and `gh` installed, `gh` logged in, `git ship` on PATH). Then it:

1. creates `~/repos/<name>` as a uv project, with `jupyter` and `ipykernel` in the `dev` group
2. commits `README.md`, `.ship` and `.gitignore`. uv's other starter files are left uncommitted, so you can delete any you don't need.
3. creates the public GitHub repo and pushes `main`, `test` and `dev`
4. runs `git ship init`
5. leaves you in the new folder, on `dev`
