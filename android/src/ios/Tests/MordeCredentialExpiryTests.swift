import Foundation

@main
enum MordeCredentialExpiryTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_793_548_800)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let nowString = formatter.string(from: now)
        let soonString = formatter.string(from: now.addingTimeInterval(7 * 24 * 60 * 60))
        let futureString = formatter.string(from: now.addingTimeInterval(7 * 24 * 60 * 60 + 1))

        precondition(MordeCredentialExpiry.status(expiresAt: nowString, now: now) == .expired)
        precondition(MordeCredentialExpiry.status(expiresAt: soonString, now: now) == .expiringSoon)
        precondition(MordeCredentialExpiry.status(expiresAt: futureString, now: now) == .valid)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: nowString, now: now) == 0)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: futureString, now: now) == 7 * 24 * 60 * 60 + 1)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: nil, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: nowString, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: nil, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential(nil, expiresAt: futureString, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: futureString, now: now) == "secret")
        precondition(MordeCredentialExpiry.status(expiresAt: "invalid", now: now) == nil)
        let attempt = MordeLoginAttempt.fingerprint(server: "https://morde.example", name: "alice", password: "secret")
        precondition(attempt.count == 64)
        precondition(attempt == MordeLoginAttempt.fingerprint(server: "https://morde.example", name: "alice", password: "secret"))
        precondition(attempt != MordeLoginAttempt.fingerprint(server: "https://morde.example", name: "alice", password: "changed"))

        print("Morde credential expiry checks passed")
    }
}
