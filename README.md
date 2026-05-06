# swift-committer

A Swift command-line tool that uses [Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels) to analyze your staged git changes and automatically generate a [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) message, then commit them — no arguments required.

## Requirements

- macOS 26+
- Xcode 26+
- Apple Intelligence enabled (System Settings → Apple Intelligence & Siri)
- An Apple Silicon Mac

## Installation

Clone the repository and build the release binary:

```bash
git clone https://github.com/its-the-vibe/swift-committer.git
cd swift-committer
make build
```

Optionally, install the binary to a directory on your `PATH`:

```bash
cp .build/release/swift-committer /usr/local/bin/swift-committer
```

## Usage

Stage your changes with `git add`, then run:

```bash
swift-committer
```

The tool will:

1. Show the current `git status`
2. Read the staged diff via `git --no-pager diff --staged`
3. Use Apple Foundation Models to generate a [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) message
4. Commit the staged changes with the generated message

No command-line arguments are needed.

## Development

| Command       | Description                              |
|---------------|------------------------------------------|
| `make build`  | Build a release binary                   |
| `make run`    | Build and run against the current repo   |
| `make clean`  | Remove build artifacts                   |

## Commit Message Format

Generated messages follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

```
<type>: <subject>

[optional body]

[optional footer]
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

## How It Works

`swift-committer` is a port of [git-committer](https://github.com/its-the-vibe/git-committer) (originally written in Go using GitHub Copilot) to Swift, leveraging Apple's on-device Foundation Models for private, local commit message generation.
