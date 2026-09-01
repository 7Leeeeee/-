import Foundation
import WidgetKit

enum SharedDiskStore {
    static let appGroupID = "group.com.personal.mytimetable"
    static let fileName = "my-timetable-snapshot.json"

    static func load() -> AppSnapshot {
        guard let data = try? Data(contentsOf: snapshotURL),
              let snapshot = try? decoder.decode(AppSnapshot.self, from: data)
        else { return DefaultData.snapshot }
        return snapshot
    }

    static func save(_ snapshot: AppSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try FileManager.default.createDirectory(
            at: snapshotURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: snapshotURL, options: [.atomic])
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static var snapshotURL: URL {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            return groupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
