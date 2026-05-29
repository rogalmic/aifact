# AI Factory Skills

A generic repository for AI "skills" (custom system prompts and instructions) that standardizes software development workflows across different AI assistants.

## Included Skills

- **`orchestrator.md`**: A strict, fully containerized software development agent that manages projects using Docker and Makefiles.
- **`porter.md`**: A specialized agent that ports existing codebases into the Orchestrator pipeline format.

## Installation

You can apply these skills to any local project. The installation script will automatically configure your project for various AI tools by concatenating all available skills.

1. Clone this repository anywhere on your machine.
2. Run the `install.sh` script from your target project directory:

```bash
cd /path/to/my-project
/path/to/aifact/install.sh
```

Alternatively, you can provide the target directory as the first argument:

```bash
/path/to/aifact/install.sh /path/to/my-project
```

### Supported AI Tools

The `install.sh` script currently copies the combined skill instructions to:
- `.cursorrules` (Cursor)
- `.windsurfrules` (Windsurf)
- `CLAUDE.md` (Claude Code)
- `.github/copilot-instructions.md` (GitHub Copilot)
- `.antigravity/instructions.md` (Antigravity CLI / Generic)
