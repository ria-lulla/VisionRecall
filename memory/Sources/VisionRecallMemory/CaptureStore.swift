import Foundation

public struct Capture: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let capturedAt: Date
    public let fileName: String

    public init(id: UUID = UUID(), capturedAt: Date, fileName: String) {
        self.id = id
        self.capturedAt = capturedAt
        self.fileName = fileName
    }
}

public struct CaptureRetentionPolicy: Equatable, Sendable {
    public let maximumCount: Int
    public let maximumAge: TimeInterval

    public init(maximumCount: Int = 30, maximumAge: TimeInterval = 24 * 60 * 60) {
        self.maximumCount = max(0, maximumCount)
        self.maximumAge = max(0, maximumAge)
    }
}

public enum CaptureStoreError: Error, Equatable {
    case emptyImageData
    case captureNotFound
}

public protocol CaptureStoring: Sendable {
    func save(imageData: Data, capturedAt: Date) async throws -> Capture
    func recentCaptures() async throws -> [Capture]
    func imageData(for capture: Capture) async throws -> Data
    func clear() async throws
}

/// Persists a deliberately small, short-lived gallery of user-initiated captures.
///
/// The store is intended for the app cache, never for a user-visible photo library.
/// Both the directory and every image are marked as excluded from backups.
public actor CaptureStore: CaptureStoring {
    private let fileManager: FileManager
    private let directory: URL
    private let indexURL: URL
    private let retentionPolicy: CaptureRetentionPolicy
    private var captures: [Capture]

    public init(
        retentionPolicy: CaptureRetentionPolicy = CaptureRetentionPolicy(),
        fileManager: FileManager = .default
    ) throws {
        try self.init(
            directory: Self.cacheDirectory(fileManager: fileManager),
            retentionPolicy: retentionPolicy,
            fileManager: fileManager
        )
    }

    public init(
        directory: URL,
        retentionPolicy: CaptureRetentionPolicy = CaptureRetentionPolicy(),
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager
        self.directory = directory
        self.indexURL = directory.appending(path: "index.json")
        self.retentionPolicy = retentionPolicy

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.excludeFromBackup(directory)
        let loadedCaptures = try Self.loadIndex(at: indexURL)
            .sorted { $0.capturedAt > $1.capturedAt }
        let retainedCaptures = Self.retainedCaptures(
            from: loadedCaptures,
            now: Date(),
            policy: retentionPolicy
        )
        self.captures = retainedCaptures

        let retainedIDs = Set(retainedCaptures.map(\.id))
        for capture in loadedCaptures where !retainedIDs.contains(capture.id) {
            try? fileManager.removeItem(at: directory.appending(path: capture.fileName))
        }
        if retainedCaptures != loadedCaptures {
            try Self.writeIndex(retainedCaptures, to: indexURL)
        }
    }

    public static func cacheDirectory(fileManager: FileManager = .default) throws -> URL {
        guard let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return cachesURL.appending(path: "Captures", directoryHint: .isDirectory)
    }

    public func save(imageData: Data, capturedAt: Date = Date()) throws -> Capture {
        guard !imageData.isEmpty else {
            throw CaptureStoreError.emptyImageData
        }

        let capture = Capture(capturedAt: capturedAt, fileName: "\(UUID().uuidString).jpg")
        let imageURL = directory.appending(path: capture.fileName)
        try imageData.write(to: imageURL, options: .atomic)
        try Self.excludeFromBackup(imageURL)

        captures.append(capture)
        captures.sort { $0.capturedAt > $1.capturedAt }
        try prune(now: capturedAt)
        return capture
    }

    public func recentCaptures() throws -> [Capture] {
        try prune(now: Date())
        return captures
    }

    public func imageData(for capture: Capture) throws -> Data {
        guard captures.contains(capture) else {
            throw CaptureStoreError.captureNotFound
        }
        return try Data(contentsOf: directory.appending(path: capture.fileName))
    }

    public func clear() throws {
        // Remove every item in this dedicated directory, including an image written
        // before a crash could update the index.
        for itemURL in try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) {
            try fileManager.removeItem(at: itemURL)
        }
        captures.removeAll()
        try persistIndex()
    }

    private func prune(now: Date) throws {
        let retained = Self.retainedCaptures(from: captures, now: now, policy: retentionPolicy)
        let retainedIDs = Set(retained.map(\.id))

        for capture in captures where !retainedIDs.contains(capture.id) {
            try? fileManager.removeItem(at: directory.appending(path: capture.fileName))
        }
        captures = retained
        try persistIndex()
    }

    private func persistIndex() throws {
        try Self.writeIndex(captures, to: indexURL)
    }

    private static func retainedCaptures(
        from captures: [Capture],
        now: Date,
        policy: CaptureRetentionPolicy
    ) -> [Capture] {
        let cutoff = now.addingTimeInterval(-policy.maximumAge)
        return Array(
            captures
                .filter { $0.capturedAt >= cutoff }
                .sorted { $0.capturedAt > $1.capturedAt }
                .prefix(policy.maximumCount)
        )
    }

    private static func writeIndex(_ captures: [Capture], to indexURL: URL) throws {
        let data = try JSONEncoder().encode(captures)
        try data.write(to: indexURL, options: .atomic)
        try excludeFromBackup(indexURL)
    }

    private static func loadIndex(at indexURL: URL) throws -> [Capture] {
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            return []
        }
        return try JSONDecoder().decode([Capture].self, from: Data(contentsOf: indexURL))
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}
