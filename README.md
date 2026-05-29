# AI Factory

A set of AI "skills" and "runbooks" that standardize software development workflows across different AI coding assistants. The core idea: **the host machine needs only Docker installed** — everything else runs in containers, orchestrated by the AI through Makefiles.

## Prerequisites

- **Linux or macOS**: Docker and Git must be installed.
- **Windows**: You **must** use WSL2 (Windows Subsystem for Linux). Docker and Git must be installed and running *inside* your WSL2 distribution. Native Windows paths (PowerShell/CMD) are not supported.

## Quickstart Example

Once you have installed the `orchestrator.md` skill into your project, you can use a prompt like this to kick off a new project from scratch:

> Using orchestrator skill, create an app that manages a shopping list (add, remove, show total) that has both an API backend and a statically served SPA frontend. Do not use javascript frameworks, use pure javascript (newest ECMA script supported by modern browsers). For technology use dotnet/java/typescript - ask user before implementation. To make the UI look nice, use `https://www.skills.sh/anthropics/skills/frontend-design` skill together with nice css based animations. Use sqlite for preserving state.

The Orchestrator will automatically prompt you for the specific Docker images, create the containerized Makefiles, and execute the full pipeline to build, test, and document both the frontend and backend components.

## Repository Structure

```
aifact/
├── skills/              ← persistent instructions, installed into AI tool config
│   └── orchestrator.md
├── runbooks/            ← on-demand instructions, referenced when needed
│   └── porter.md
├── install.sh
└── README.md
```

### Skills vs Runbooks

| | Skills | Runbooks |
|---|---|---|
| **Loaded** | Always (baked into system prompt) | On demand (referenced in chat) |
| **Installed by** | `install.sh` | You, by pointing the AI at the file |
| **Purpose** | Persistent workflow rules | One-time or occasional operations |
| **Example** | `orchestrator.md` — ongoing dev workflow | `porter.md` — one-time project onboarding |

## Installing Skills

The `install.sh` script copies all files from `skills/` into the appropriate configuration locations for each AI tool.

```bash
# Install to current directory
/path/to/aifact/install.sh

# Install to a specific project
/path/to/aifact/install.sh /path/to/my-project

# Force overwrite existing config files
/path/to/aifact/install.sh -f /path/to/my-project
```

This creates/updates:

| AI Tool | Config File |
|---|---|
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Antigravity | `.antigravity/instructions.md` |

> **Note:** Existing files are not overwritten unless you pass `-f`.

## Using Runbooks

Runbooks are **not installed** — they are standalone instructions you reference when needed. Every major AI coding tool supports pointing at a file in chat:

| AI Tool | How to invoke a runbook |
|---|---|
| Cursor | Type `@porter.md` in chat |
| Claude Code | Type `@porter.md` or say "read runbooks/porter.md" |
| Windsurf | Type `@porter.md` in chat |
| GitHub Copilot | Type `#file:porter.md` in chat |
| Antigravity | Type `@porter.md` or say "read runbooks/porter.md" |

### Available Runbooks

#### `porter.md` — Project Onboarding

Brings an existing codebase under Orchestrator management. This is a **one-time operation**: you run it once to generate the `STACK.md`, `Makefile`, documentation, and test evidence files. After porting completes, the Orchestrator skill takes over in update mode.

**Example workflow:**
1. You have a legacy Node.js project with no standardized build pipeline.
2. Open the project in your AI tool and reference `porter.md`.
3. The AI scans the project, asks you to pick a Docker image version, generates the Makefile and docs.
4. Done — from now on, the installed Orchestrator skill handles all future work.

## Included Skills

#### `orchestrator.md` — Containerized Development Workflow

A structured development agent that creates and modifies software using a fully containerized pipeline. Key features:

- **Docker-only builds** — no SDKs or runtimes installed on the host
- **Makefile as universal interface** — `build`, `unittest`, `statictest`, `autotest`, `clean`, `deps`
- **Automatic documentation** — `STACK.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, test evidence files
- **Multi-component support** — spawns subagents for polyglot projects
- **Security-conscious** — static analysis and security scanning built into the pipeline
