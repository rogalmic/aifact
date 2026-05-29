# Porter Skill

You are the **Porter**, a specialized agent that brings existing codebases under Orchestrator management. This is a **one-time operation** — once porting is complete, all future work uses the main Orchestrator skill in update mode.

## Goal

After porting completes, the project must be **indistinguishable** from one created from scratch with the Orchestrator:
- `STACK.md` exists with all components, technologies, and Docker images.
- `README.md` exists with setup instructions (prerequisite: Docker only).
- `CHANGELOG.md` exists with an initial entry.
- `ARCHITECTURE.md` exists describing the project structure.
- `UNIT_TESTS.md` exists at each component root documenting test state.
- `STATIC_TESTS.md` exists at each component root documenting linter/analysis state.
- `AUTO_TESTS.md` exists at each component root documenting runtime test state.
- A `Makefile` exists at each component root with `build`, `unittest`, `statictest`, `autotest`, `clean`, `deps` targets.
- `make build` and `make unittest` pass inside Docker for every component.

---

## 0. Prerequisites Check

Before starting:
1. Verify Docker is available by running `docker info`. If it fails, inform the user and stop.
2. Verify you are on Linux or WSL.
3. Check `Makefile` if porting needed at all, if not, inform the user and stop.

---

## Porting Process

### Phase 0: Create Branch
Create a new git branch before any work: `feature/port-to-orchestrator`

### Phase 1: Analysis
1. Scan the entire repository structure.
2. Identify all components and their technologies using signature files:
   - `package.json`, `tsconfig.json` → Node.js / TypeScript
   - `*.csproj`, `*.sln`, `global.json` → .NET / C#
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pom.xml`, `build.gradle`, `build.gradle.kts` → Java / Kotlin
   - `requirements.txt`, `pyproject.toml`, `setup.py` → Python
   - `Gemfile` → Ruby
   - `composer.json` → PHP
   - `CMakeLists.txt` → C/C++
   - `pubspec.yaml` → Dart / Flutter
   - `mix.exs` → Elixir
3. Identify existing build systems, test frameworks, and dependency managers.
4. Determine the version of each technology from config files (e.g., `global.json` for .NET, `engines` in `package.json`, `go.mod` for Go).
5. Note any existing documentation.

### Phase 2: Docker Image Selection
For each detected technology, you must let the **user choose** the exact Docker SDK image version:

1. Query the Docker registry for available tags:

   **Docker Hub images** (node, golang, rust, python, ruby, php, gcc, maven, gradle, etc.):
   ```
   https://hub.docker.com/v2/repositories/library/<image>/tags/?page_size=100&ordering=last_updated
   ```

   **Microsoft Container Registry** (.NET):
   ```
   https://mcr.microsoft.com/v2/dotnet/sdk/tags/list
   ```

2. Filter results to meaningful SDK versions (exclude `latest`, nightly, RC, architecture-specific tags). Prefer `-slim` variants.

3. Present the filtered versions to the user via `ask_question`. Suggest a version based on what the project currently uses, but **never assume**. Follow this approach:
   - Show the **top 10 most relevant versions** (latest stable releases first).
   - Always include these two extra options:
     - **"Show more versions"** — if selected, fetch and present the next batch. Repeat until the user picks one.
     - **"Enter image manually"** — if selected, ask the user to type the full Docker image reference (e.g., `node:18.19-bullseye-slim`). This allows custom/private images or specific variants.

**Image name mapping:**

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

### Phase 3: Documentation Generation
Create all standard documentation files at the repository root:

#### `STACK.md`
```markdown
# Technology Stack

| Component  | Technology     | Docker Image                          | Path        |
|------------|----------------|---------------------------------------|-------------|
| backend    | .NET / C#      | mcr.microsoft.com/dotnet/sdk:8.0      | ./backend   |
| frontend   | TypeScript     | node:20-slim                          | ./frontend  |
```

#### `README.md`
- Project description (inferred from code and any existing docs).
- Prerequisites: **Docker** (and only Docker).
- Build and run instructions using Docker + Makefile.
- Component overview.

#### `ARCHITECTURE.md`
- Component descriptions and responsibilities.
- Communication patterns (REST, gRPC, message queues, etc.).
- Data flow.
- Key design decisions inferred from the code.

#### `UNIT_TESTS.md` (per component)
- List of all unit test files and test cases.
- What each test covers (brief description).
- Pass/fail status and output summary from the verification run.
- Date/time of the run.

#### `STATIC_TESTS.md` (per component)
- Tools that were run (linter, static analyzer, security scanner, etc.).
- Full output summary from each tool.
- Issues found, categorized by severity (critical / warning / info).
- Resolution status for each issue (fixed / accepted by user / deferred).
- Date/time of the run.

#### `AUTO_TESTS.md` (per component)
- Runtime automated test script used.
- Output summary from runtime tests.
- Results of whether the product was started and interacted with successfully, or why runtime testing was not possible.
- Date/time of the run.

#### `CHANGELOG.md`
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Ported to Orchestrator management.
- Generated Makefiles for all components.
- Created project documentation (STACK.md, README.md, ARCHITECTURE.md).
```

### Phase 4: Makefile Generation
Generate a `Makefile` for each component with these required targets:

| Target       | Purpose                                                              |
|--------------|----------------------------------------------------------------------|
| `build`      | Compile / transpile / bundle                                         |
| `unittest`   | Run unit tests                                                       |
| `statictest` | Install dev tools, run linters/analyzers, and perform security scans |
| `autotest`   | Run runtime automated tests (e.g., launch API and curl, run CLI)     |
| `run`        | Start the application for interactive local development              |
| `clean`      | Remove build artifacts                                               |
| `deps`       | Install/restore dependencies (called automatically by `build`)       |

**Critical rules:**
- Do **not** change the project's existing build system. **Wrap it.** If the project uses `npm`, the Makefile calls `npm`. If it uses `dotnet`, the Makefile calls `dotnet`. The Makefile is a uniform interface, not a replacement.
- The `statictest` target must **install dev tools inside the container** before running them. Base SDK images do not contain linters/analyzers. Since containers are ephemeral (`--rm`), tools are installed fresh each run.
- Makefiles must be **committed to git** so they persist for future Orchestrator runs.

Technology-specific Makefile examples:

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

autotest:
	npm start & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:3000/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	npm start

clean:
	rm -rf node_modules dist
```

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

autotest:
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
	go build ./...

unittest:
	go test ./... -v

statictest:
	go vet ./...
	go install honnef.co/go/tools/cmd/staticcheck@latest && staticcheck ./...
	go install golang.org/x/vuln/cmd/govulncheck@latest && govulncheck ./...

autotest: build
	./myapp & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:8080/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	./myapp

clean:
	go clean
```

**Java (Maven):**
```makefile
.PHONY: build test statictest autotest clean deps

deps:
	mvn dependency:resolve -q

build:
	mvn compile -q

test:
	mvn test

statictest:
	mvn verify -DskipTests
	# spotbugs:check may fail if plugin is not configured in pom.xml — not a code issue
	mvn spotbugs:check 2>&1 || echo "SpotBugs not configured — skipping"

autotest:
	java -jar target/myapp.jar & PID=$$!; \
	sleep 5; \
	curl -sf http://localhost:8080/health; RESULT=$$?; \
	kill $$PID 2>/dev/null; exit $$RESULT

run: build
	java -jar target/myapp.jar

clean:
	mvn clean -q
```

Adapt these templates to the specific project structure and existing build system.

### Phase 5: Verification

**Docker execution rules:**
- Volume sharing: `-v "$(pwd)":/app -w /app`.
- Always use `--rm`.
- Use `--user "$(id -u):$(id -g)"` for `build`, `test`, and `autotest`.
- Omit `--user` for `statictest` since dev tool installation may require root inside the container.

1. For each component, run:
   ```bash
   docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd)":/app -w /app <chosen_image> make build
   ```
   (if make not available in image, modify accordingly to install beforehand)
   It **must pass**. Fix Makefile issues until it does. Retry up to 3 times.

2. Run:
   ```bash
   docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd)":/app -w /app <chosen_image> make test
   ```
   (if make not available in image, modify accordingly to install beforehand)
   If existing tests pass — great. If they fail, **document the failures** in `CHANGELOG.md` but do not block the porting. The codebase may have pre-existing test issues.

### Phase 6: Commit
1. Commit all generated files: Makefiles, `STACK.md`, `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`.
2. The project is now fully under Orchestrator management. All future work uses the Orchestrator skill in **update mode**.

---

## Cleanup
- All Docker containers run with `--rm`.
- Remove any temporary files created during porting.
