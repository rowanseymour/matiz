import Foundation

/// Translates by shelling out to `claude -p`. Runs through a login shell so the
/// user's normal PATH (homebrew, nvm, etc.) applies.
public struct ClaudeCLITranslator: TranslationService {
    public let model: String
    public let timeout: TimeInterval

    public init(model: String = "haiku", timeout: TimeInterval = 120) {
        self.model = model
        self.timeout = timeout
    }

    public func translate(_ request: TranslationRequest) async throws -> [TranslationVariant] {
        let trimmed = request.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptySource }

        let prompt = PromptBuilder.prompt(for: request)
        let output = try await Self.run(prompt: prompt, model: model, timeout: timeout)
        return try VariantParser.parse(output)
    }

    /// Known install locations, tried before falling back to a PATH lookup. The app
    /// may be launched with a PATH that doesn't include the CLI (Finder, `swift run`
    /// from another shell), so resolution can't rely on PATH alone.
    private static let cliCandidates: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "\(home)/bin/claude",
        ]
    }()

    public static func locateCLI() -> String? {
        let fm = FileManager.default
        if let found = cliCandidates.first(where: { fm.isExecutableFile(atPath: $0) }) {
            return found
        }
        // Fall back to the user's login-shell PATH.
        if let output = try? runSync(command: "command -v claude", prompt: "", timeout: 15) {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty { return path }
        }
        return nil
    }

    private static func run(prompt: String, model: String, timeout: TimeInterval) async throws -> String {
        guard let cli = locateCLI() else {
            throw TranslationError.backendFailed(
                "claude CLI not found — checked PATH and \(cliCandidates.joined(separator: ", "))")
        }
        // Skip the user's MCP servers, settings, hooks and plugins — none are needed
        // for a one-shot translation and they only add startup latency.
        let command = "exec \(shellQuote(cli)) -p --strict-mcp-config --setting-sources '' --model \(shellQuote(model))"
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try runSync(
                        command: command, prompt: prompt, timeout: timeout))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func runSync(command: String, prompt: String, timeout: TimeInterval) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw TranslationError.backendFailed("Couldn't launch claude CLI: \(error.localizedDescription)")
        }

        stdin.fileHandleForWriting.write(Data(prompt.utf8))
        stdin.fileHandleForWriting.closeFile()

        let watchdog = DispatchWorkItem { process.terminate() }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: watchdog)

        // Drain stderr concurrently so a chatty process can't fill the pipe and stall.
        var stderrData = Data()
        let stderrDrained = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
            stderrDrained.signal()
        }

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        watchdog.cancel()
        stderrDrained.wait()

        let output = String(decoding: stdoutData, as: UTF8.self)
        guard process.terminationStatus == 0 else {
            if process.terminationReason == .uncaughtSignal {
                throw TranslationError.backendFailed("claude CLI timed out after \(Int(timeout))s.")
            }
            // The claude CLI reports some failures (e.g. auth) on stdout, others on stderr.
            let message = [stderrData, stdoutData]
                .map { String(decoding: $0, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            throw TranslationError.backendFailed(message ?? "claude CLI failed (is it installed and logged in?)")
        }
        return output
    }

    public static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
