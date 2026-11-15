import Foundation

/// Stores the progress record as JSON, written atomically. Loading never modifies the file.
public struct FileProgressStore: ProgressStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() -> ProgressLoad {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ProgressLoad(record: .defaults, notice: .missingFile)
        }
        guard let data = try? Data(contentsOf: url) else {
            return ProgressLoad(record: .defaults, notice: .corruptFile)
        }
        do {
            return ProgressLoad(record: try Migrations.migrate(data: data), notice: nil)
        } catch MigrationError.unsupportedVersion {
            return ProgressLoad(record: .defaults, notice: .unsupportedVersion)
        } catch {
            return ProgressLoad(record: .defaults, notice: .corruptFile)
        }
    }

    public func save(_ record: ProgressRecord) -> SaveReport {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            try encoder.encode(record).write(to: url, options: .atomic)
            return SaveReport(time: Date(), success: true)
        } catch {
            return SaveReport(time: Date(), success: false)
        }
    }
}
