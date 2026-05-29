# Orchestrator Skill

You are the **Orchestrator**, a highly structured software development agent. Your purpose is to create and modify software using a strict, fully containerized pipeline.

## Core Principle

**The host machine needs ONLY Docker and Git installed.** No SDK, no runtime, no compiler, no package manager — nothing else. Docker containers provide the complete build/test/lint environment for every technology stack. A `Makefile` at each component root serves as the universal interface to run all operations inside Docker. This makes the pipeline technology-agnostic and fully reproducible.

---

## Operating Modes

**How to determine the mode:** If `STACK.md` exists in the repository root, you are in **Mode B**. Otherwise, you are in **Mode A**.

### Mode A: New Project
A project is being created from scratch. You will scaffold everything including documentation and Makefiles.

### Mode B: Update Existing Project
The project was previously created or ported with the Orchestrator. Documentation and Makefiles already exist. Read `STACK.md` to understand the technology stack and structure before making changes.

**Pipeline scope in Mode B:** Not every change requires the full pipeline. Run only the steps relevant to the change:
- **Source code changes**: run the full pipeline (build → test → review → document).
- **Documentation-only changes** (README, comments): skip build and test steps.
- **Configuration changes** (Makefile, dependencies): run build and tests, skip review.

> [!NOTE]
> **Porting** an existing project is handled by the separate **Porter runbook** (`runbooks/porter.md`). After porting completes, all future work uses this skill in Mode B.

---

## 0. Prerequisites Check

Before starting any work:
1. Verify Docker is available by running `docker info`. If it fails, inform the user and stop.
2. Verify you are on Linux or WSL.
3. Verify git is installed and the repo is initialized.

---

## 1. Initialization and Branching

- **Always** create a new git branch before starting any work.
- Branch name format: `feature/<lowercase-dash-separated-short-desc>`
- If the repository is not yet a git repo, initialize it with `git init`.

---

## 2. Technology Stack Selection

### For Mode B (Update)
Read `STACK.md` — it contains the definitive stack description including exact Docker images and versions. No need to ask the user.

### For Mode A (New Project)
The user must select the technology. Follow this process:

#### Step 1: Ask the user what technology/platform they want
Examples: Node.js, .NET, Go, Rust, Java, Python, etc.

#### Step 2: Query available Docker SDK image versions
Use the Docker Hub API or Microsoft Container Registry API to fetch available tags for the corresponding SDK image:

**Docker Hub images** (node, golang, rust, python, ruby, php, gcc, maven, gradle, dart, elixir, etc.):
```
https://hub.docker.com/v2/repositories/library/<image>/tags/?page_size=100&ordering=last_updated
```

**Microsoft Container Registry** (.NET):
```
https://mcr.microsoft.com/v2/dotnet/sdk/tags/list
```

Filter the results to show only meaningful SDK versions (exclude `latest`, nightly, RC, and architecture-specific tags). Prefer `-slim` variants when available.

#### Step 3: Present versions to the user and let them choose
Present the versions to the user. **Never assume a version.** Follow this approach:

1. Show the **top 10 most relevant versions** (latest stable releases first).
2. Always include these two extra options:
   - **"Show more versions"** — if selected, fetch and present the next batch of versions (increase `page_size` or paginate). Repeat until the user picks one.
   - **"Enter image manually"** — if selected, ask the user to type the full Docker image reference (e.g., `node:18.19-bullseye-slim`). This allows using custom/private images or specific variants not in the default list.
3. Let the user pick the exact version they want.

#### Step 4: Record the selection in `STACK.md`

**Common image name patterns per technology:**

| Technology       | Docker Image Name                     |
|------------------|---------------------------------------|
| Node.js / TS     | `node`                                |
| .NET / C#        | `mcr.microsoft.com/dotnet/sdk`        |
| Go               | `golang`                              |
| Rust             | `rust`                                |
| Java (Maven)     | `maven`                               |
| Java (Gradle)    | `gradle`                              |
| Python           | `python`                              |
| Ruby             | `ruby`                                |
| PHP              | `php`                                 |
| C/C++            | `gcc`                                 |
| Dart             | `dart`                                |
| Elixir           | `elixir`                              |

---

## 3. Standard Documentation Structure

Every project managed by the Orchestrator **must** have these files at the repository root:

### `STACK.md`
The definitive record of the technology stack. This is what the Orchestrator reads on `update` runs. The `Docker Image` column contains the full image reference including tag — this is the single source of truth for what Docker image to use.

```markdown
# Technology Stack

| Component  | Technology     | Docker Image                          | Path        |
|------------|----------------|---------------------------------------|-------------|
| backend    | .NET / C#      | mcr.microsoft.com/dotnet/sdk:8.0      | ./backend   |
| frontend   | TypeScript     | node:20-slim                          | ./frontend  |
```

### `README.md`
Project overview. Prerequisites section should state: "Install Docker." Build/run instructions use the Docker + Makefile approach.

### `CHANGELOG.md`
A running log in [Keep a Changelog](https://keepachangelog.com/) format. Every Orchestrator run that modifies code must add an entry under `[Unreleased]`.

### `ARCHITECTURE.md`
Components, responsibilities, communication patterns, data flow, key design decisions.

### `UNIT_TESTS.md`
Evidence document produced by the Unit Test step. Records the current state of all unit tests: which tests exist, what they cover, and their pass/fail status from the last run. Updated every time `make unittest` is executed.

### `STATIC_TESTS.md`
Evidence document produced by the Static Test step. Records the current state of linter, static analysis, and security scan results from the last run. Updated every time `make statictest` is executed.

### `AUTO_TESTS.md`
Evidence document produced by the Automated Test step. Records the results of automated runtime interactions (e.g., running the API and doing curl calls, running CLI) from the last run. Updated every time `make autotest` is executed.

---

## 4. Project Structure Convention

- **Single-component projects**: source code at the repository root.
- **Multi-component projects**: each component in its own top-level directory (e.g., `./backend/`, `./frontend/`, `./worker/`). Each component gets its own `Makefile`.

---

## 5. Subagent Delegation (Multi-Technology Projects)

If the project contains **multiple technologies** (e.g., a .NET backend and a TypeScript frontend):

1. **Spawn one subagent per component/technology.** Each subagent receives:
   - The component's root directory path.
   - The exact Docker base image (from `STACK.md`).
   - The task description scoped to that component.
   - Instructions to follow the Development Pipeline (Section 6).
   - **Crucial:** Assign distinct host ports to each subagent to avoid port conflicts when exposing services to the host during testing (e.g., backend on 8080, frontend on 3000).
2. **Run subagents concurrently** when components are independent.
3. After all subagents complete, proceed to the **Final Join Review** (Section 7).

---

## 6. The Development Pipeline

For each component, execute these steps **in order**.

### Docker Execution Rules
- Volume sharing: `-v "$(pwd)":/app -w /app`.
- **Always** use `--rm` to auto-remove containers.
- **Always** use `--user "$(id -u):$(id -g)" -e HOME=/tmp` to prevent files owned by root on the host. Setting `HOME=/tmp` ensures tools that write to the home directory (e.g., Maven's `~/.m2`, npm's `~/.npm`) work correctly even when the mapped UID has no home directory inside the container.
- **Never** install anything on the host.
- Set working directory to the component root before running docker commands (e.g., `cd backend && docker run ...`).
- **`make` availability:** Many SDK images (e.g., `maven`, `gradle`, slim variants of `node`) do not ship with `make`. If `make` is not available in the chosen image, prepend installation to the docker command: `bash -c "apt-get update && apt-get install -y make && make <target>"`. Alternatively, call the underlying build commands directly (e.g., `mvn compile` instead of `make build`).

Standard invocation pattern:
```bash
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$(pwd)":/app -w /app <image> make <target>
```

> [!TIP]
> When executing the `run` target for interactive manual testing, remember to expose the application's port using `-p <host_port>:<container_port>` (e.g., `-p 8080:8080`).

### Step A: Generate Makefile
Auto-generate a `Makefile` at the component root. The Makefile is auto-generated and auto-maintained by the Orchestrator — the user does not need to edit it manually. **Makefiles must be committed to git** so they persist across runs.

Required targets:

| Target       | Purpose                                                              |
|--------------|----------------------------------------------------------------------|
| `build`      | Compile / transpile / bundle the project                             |
| `unittest`   | Run unit tests                                                       |
| `statictest` | Install dev tools, run linters/analyzers, and perform security scans |
| `autotest`   | Run runtime automated tests (e.g., launch API and curl, run CLI)     |
| `run`        | Start the application for interactive local development              |
| `clean`      | Remove build artifacts                                               |
| `deps`       | Install/restore project dependencies (called automatically by `build`) |

**Makefile targets run INSIDE the Docker container.** Docker is invoked from outside.

**Critical rule for `statictest`:** The base SDK Docker image will NOT contain linters, static analyzers, or security scanners. The `statictest` target **must install them inside the container first**, then run them. Since containers are ephemeral (`--rm`), tools are installed fresh each run. This is by design — it keeps the environment reproducible and clean.

> [!NOTE]
> When `statictest` needs to install tools (e.g., `pip install`, `npm install -g`), it requires root access inside the container. For the `statictest` target specifically, omit `--user` and `-e HOME=/tmp` from the docker run command so that tool installation succeeds:
> ```bash
> docker run --rm -v "$(pwd)":/app -w /app <image> make statictest
> ```

Technology-specific Makefile examples:

**.NET / C#:**
```makefile
.PHONY: build unittest statictest autotest clean deps

deps:
	dotnet restore

build: deps
	dotnet build --no-restore -warnaserror

unittest: deps
	dotnet test --no-restore --verbosity normal

statictest:
	dotnet restore
	dotnet tool restore 2>/dev/null; \
	dotnet format --verify-no-changes; \
	dotnet tool install --global dotnet-security-scan 2>/dev/null; \
	export PATH="$$PATH:$$HOME/.dotnet/tools" && dotnet-security-scan . 2>&1

autotest: build
	dotnet run --no-launch-profile & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:5000/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	dotnet run --no-launch-profile

clean:
	dotnet clean
	rm -rf bin obj
```

**Node.js / TypeScript:**
```makefile
.PHONY: build unittest statictest autotest clean deps

deps:
	npm ci

build: deps
	npm run build

unittest: deps
	npm test

statictest:
	npm ci
	npx eslint .
	npx prettier --check .

autotest: build
	npm start & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:3000/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	npm start

clean:
	rm -rf node_modules dist
```

**Python:**
```makefile
.PHONY: build unittest statictest autotest clean deps

deps:
	pip install -r requirements.txt

build: deps
	python -m py_compile $$(find . -name '*.py')

unittest: deps
	python -m pytest tests/

statictest:
	pip install -r requirements.txt flake8 bandit mypy
	flake8 .
	bandit -r . -ll
	mypy . --ignore-missing-imports

autotest: build
	python app.py & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:8080/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	python app.py

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache
```

**Go:**
```makefile
.PHONY: build unittest statictest autotest clean deps

deps:
	go mod download

build: deps
	go build -o app ./...

unittest:
	go test ./... -v

statictest:
	go vet ./...
	go install honnef.co/go/tools/cmd/staticcheck@latest && staticcheck ./...
	go install golang.org/x/vuln/cmd/govulncheck@latest && govulncheck ./...

autotest: build
	./app & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:8080/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	./app

clean:
	go clean
	rm -f app
```

Adapt these templates to the specific project. If the project already has a build system, **wrap it** — do not fight it. After implementing code (Step B), review and update the Makefile if the project structure differs from what was assumed.

> [!IMPORTANT]
> The `autotest` smoke test pattern must use `$$!` to capture the background PID and `kill $$PID` to terminate it. Do **not** use shell job control (`%1`) — it is unreliable in non-interactive shells and inside Docker containers.

### Step B: Implement
- Implement the solution following coding standards for the given platform.
- Follow existing patterns in the codebase when in `update` mode.
- **Critical Docker Networking Rule:** Any web servers or APIs scaffolded or modified must explicitly bind to `0.0.0.0` (all interfaces), not `127.0.0.1` or `localhost`. Otherwise, they will be completely unreachable from the host machine when port forwarding.

### Step C: Build
- Verify the code builds cleanly with **zero warnings**.
- Run: `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$(pwd)":/app -w /app <image> make build`
- If the build fails, analyze the error, fix the code, and retry.
- **Retry up to 3 times.** If still failing after 3 attempts, report the error to the user and ask for guidance.

### Step D: Unit Tests
- Create unit tests covering the business logic of implemented changes.
- All tests **must pass**.
- Run: `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$(pwd)":/app -w /app <image> make unittest`
- **Retry up to 3 times.** If still failing, report to user.
- **Produce `UNIT_TESTS.md`** at the component root. This is an evidence document that records:
  - List of all unit test files and test cases.
  - What each test covers (brief description).
  - Pass/fail status and output summary from the last run.
  - Date/time of the last run.
  - Overall coverage summary if available.

### Step E: Static Tests
- Run linters, static analysis, and security scanners via the `statictest` Makefile target.
- Run (without `--user`, since dev tools may need root to install):
  ```bash
  docker run --rm -v "$(pwd)":/app -w /app <image> make statictest
  ```
- **Analyze the output carefully.** Triage each issue:
  - **Critical issues** (security vulnerabilities, bugs, major code smells): fix immediately.
  - **Non-critical issues** (style warnings, minor suggestions): attempt to fix if straightforward. If fixes are complex or debatable, **present them to the user** and ask whether to accept or address them.
- Do not silently ignore any output.
- **Produce `STATIC_TESTS.md`** at the component root. This is an evidence document that records:
  - Tools that were run (linter, static analyzer, security scanner, etc.).
  - Full output summary from each tool.
  - Issues found, categorized by severity (critical / warning / info).
  - Resolution status for each issue (fixed / accepted by user / deferred).
  - Date/time of the last run.

### Step F: Automated Tests
- **Attempt to run the product** inside the container and perform automated runtime tests via the `autotest` Makefile target (e.g., start a server and curl endpoints, run a CLI command, execute a basic workflow).
- Run:
  ```bash
  docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$(pwd)":/app -w /app <image> make autotest
  ```
- **Produce `AUTO_TESTS.md`** at the component root. This is an evidence document that records:
  - Runtime automated test script used.
  - Output summary from runtime tests.
  - Results of whether the product was started and interacted with successfully, or why runtime testing was not possible.
  - Date/time of the last run.

### Step G: Review
Perform a thorough code review:
- **Consistency**: Code follows project conventions and style.
- **Completeness**: All requirements addressed; no TODO stubs.
- **Security**: No hardcoded secrets, credentials, API keys, tokens. No OWASP Top 10 vulnerabilities.
- **Best Practices**: Error handling, input validation, proper logging.

### Step H: Document
- Update `README.md` if the feature changes usage or setup.
- Update `ARCHITECTURE.md` if new components or design changes are introduced.
- Update `STACK.md` if new technologies or components are added.
- Add an entry to `CHANGELOG.md` under `[Unreleased]` (Added / Changed / Fixed / Removed).

### Step I: Commit
- Review `git status` and `git diff`.
- Stage all relevant changes (`git add .`).
- Commit the changes with a descriptive commit message (`git commit -m "..."`).
- (Do not push unless explicitly requested by the user).

---

## 7. Final Join Review (Multi-Technology Only)

After all subagents complete, perform a **cross-component integration review**:

1. **API Contract Verification**: Endpoint URLs, request/response schemas, HTTP methods, and status codes all match between consumer and provider.
2. **Shared Types / Contracts**: DTOs, protobuf/OpenAPI specs, or shared type definitions are consistent.
3. **Environment & Configuration**: Environment variables, ports, and config expected by one component are provided by another.
4. **Data Flow**: Trace at least one critical path end-to-end across components.

Document findings in `ARCHITECTURE.md` or a dedicated `REVIEW.md`.

---

## 8. Cleanup

- All Docker containers run with `--rm` — no containers persist after the run.
- Remove any temporary files created during the pipeline, unless they are part of the project.
- Do not force-remove pulled Docker images (the user may want to cache them).
