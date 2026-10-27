import Foundation
import CryptoKit

enum MordeLoginAttempt {
    static func fingerprint(server: String, name: String, password: String) -> String {
        let input = Data("\(server)\u{0}\(name)\u{0}\(password)".utf8)
        return SHA256.hash(data: input).map { String(format: "%02x", $0) }.joined()
    }
}

enum MordeCredentialExpiryStatus: Equatable {
    case expired
    case expiringSoon
    case valid
}

enum MordeCredentialExpiry {
    static func parse(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }

    static func status(expiresAt raw: String, now: Date = Date()) -> MordeCredentialExpiryStatus? {
        guard let expiry = parse(raw) else { return nil }
        if expiry <= now { return .expired }
        if expiry <= now.addingTimeInterval(7 * 24 * 60 * 60) { return .expiringSoon }
        return .valid
    }

    static func validCredential(_ credential: String?, expiresAt: String?, now: Date = Date()) -> String? {
        guard let credential, !credential.isEmpty, let expiresAt,
              let status = status(expiresAt: expiresAt, now: now), status != .expired else { return nil }
        return credential
    }

    static func secondsUntilExpiry(expiresAt raw: String?, now: Date = Date()) -> TimeInterval? {
        guard let raw, let expiry = parse(raw) else { return nil }
        return max(0, expiry.timeIntervalSince(now))
    }
}
