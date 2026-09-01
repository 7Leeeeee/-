import CryptoKit
import Foundation

enum ImportCodeError: LocalizedError {
    case malformed
    case unsupportedVersion
    case checksumMismatch
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .malformed: "导入码格式不完整"
        case .unsupportedVersion: "这个导入码版本暂不支持"
        case .checksumMismatch: "导入码校验失败，可能复制不完整"
        case .invalidPayload: "导入码中的课表数据无法读取"
        }
    }
}

enum ScheduleImportCode {
    static let prefix = "MT1"

    static func encode(_ envelope: ScheduleImportEnvelope) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        return "\(prefix).\(base64URL(data)).\(checksum(data))"
    }

    static func decode(_ rawCode: String) throws -> ScheduleImportEnvelope {
        let normalized = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { throw ImportCodeError.malformed }
        guard parts[0] == Substring(prefix) else { throw ImportCodeError.unsupportedVersion }
        guard let data = dataFromBase64URL(String(parts[1])) else { throw ImportCodeError.invalidPayload }
        guard checksum(data) == String(parts[2]).lowercased() else {
            throw ImportCodeError.checksumMismatch
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(ScheduleImportEnvelope.self, from: data),
              envelope.schemaVersion == 1
        else { throw ImportCodeError.invalidPayload }
        return envelope
    }

    private static func checksum(_ data: Data) -> String {
        SHA256.hash(data: data).prefix(6).map { String(format: "%02x", $0) }.joined()
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func dataFromBase64URL(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: padding)
        return Data(base64Encoded: base64)
    }
}
