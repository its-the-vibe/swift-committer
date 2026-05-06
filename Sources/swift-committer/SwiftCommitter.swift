import Foundation
import FoundationModels

// Adapted from https://github.com/its-the-vibe/git-committer/blob/main/.github/agents/git-committer.agent.md
private let systemPrompt = """
You are an expert Git committer who specializes in examining staged changes and crafting \
clear, conventional commit messages. You understand Git workflows and follow commit \
message best practices.

When given the output of `git --no-pager diff --staged`, analyze the changes and \
generate an appropriate commit message that:
- Uses the conventional commit format: <type>: <subject>
- Has a concise subject line (50 characters or less preferred)
- Uses imperative mood ("Add feature" not "Added feature")
- Provides an optional body for complex changes
- References issue numbers if relevant
- Only includes differences present in the staged changes

Common types: feat, fix, docs, style, refactor, test, chore, ci, perf

Commit message format:
<type>: <subject>

[optional body]

[optional footer]

Output only the raw commit message itself. Do not include markdown formatting, \
code blocks, or any explanatory text.
"""

enum CommitterError: Error, CustomStringConvertible {
    case commandFailed(command: String, output: String, exitCode: Int32)
    case noStagedChanges
    case modelUnavailable(reason: String)
    case emptyCommitMessage

    var description: String {
        switch self {
        case .commandFailed(let command, let output, let exitCode):
            return "Command '\(command)' failed (exit \(exitCode)):\n\(output)"
        case .noStagedChanges:
            return "No staged changes found. Stage files with 'git add' first."
        case .modelUnavailable(let reason):
            return "Apple Foundation Models unavailable: \(reason)"
        case .emptyCommitMessage:
            return "Generated commit message was empty."
        }
    }
}

@discardableResult
func runCommand(_ command: String, arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
        let output = [stdout, stderr]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        throw CommitterError.commandFailed(command: command, output: output, exitCode: process.terminationStatus)
    }

    return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

@main
struct SwiftCommitter {
    static func main() async {
        do {
            try await run()
        } catch let error as CommitterError {
            printError("Error: \(error.description)")
            exit(1)
        } catch {
            printError("Error: \(error)")
            exit(1)
        }
    }

    static func run() async throws {
        // Show repository status
        let status = try runCommand("git", arguments: ["status"])
        print(status)
        print()

        // Get staged diff
        let diff = try runCommand("git", arguments: ["--no-pager", "diff", "--staged"])
        guard !diff.isEmpty else {
            throw CommitterError.noStagedChanges
        }

        print("Generating commit message with Apple Foundation Models...")

        // Verify model availability
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw CommitterError.modelUnavailable(reason: "\(reason)")
        }

        // Generate commit message
        let session = LanguageModelSession(instructions: systemPrompt)
        let response = try await session.respond(to: diff)
        let commitMessage = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !commitMessage.isEmpty else {
            throw CommitterError.emptyCommitMessage
        }

        print("Generated commit message:\n\(commitMessage)\n")

        // Commit with the generated message
        let commitOutput = try runCommand("git", arguments: ["commit", "-m", commitMessage])
        print(commitOutput)
    }
}
