# AI Factory Skills

A generic repository for AI "skills" (custom system prompts and instructions) that standardizes software development workflows across different AI assistants.

## Included Skills

- **`orchestrator.md`**: A strict, fully containerized software development agent that manages projects using Docker and Makefiles.
- **`porter.md`**: A specialized agent that ports existing codebases into the Orchestrator pipeline format.

## Installation

You can apply these skills to any local project. The installation script will automatically configure your project for various AI tools (Cursor, GitHub Copilot CLI, Claude Code, Windsurf, etc.).

1. Clone this repository anywhere on your machine.
2. Run the `install.sh` script from your target project directory, pointing to the script and providing the skill name:

```bash
cd /path/to/my-project
/path/to/aifact/install.sh orchestrator
```

Alternatively, you can provide the target directory as the second argument:

```bash
./install.sh orchestrator /path/to/my-project
```

### Supported AI Tools

The `install.sh` script currently copies the skill instructions to:
- `.cursorrules` (Cursor)
- `.windsurfrules` (Windsurf)
- `CLAUDE.md` (Claude Code)
- `.github/copilot-instructions.md` (GitHub Copilot)
- `.antigravity/instructions.md` (Antigravity CLI / Generic)
