import Foundation

/// Storage locations shared by the app, FileProvider and local file services.
enum MinisStoragePaths {
    // Keep these paths aligned with the legacy AIChatViewModel constants until their execution-only callers are removed.
    static let minisLinuxBaseDir = "/var/minis"
    static let minisAttachmentsLinuxDir = "/var/minis/attachments"
    static let minisOffloadsLinuxDir = "/var/minis/offloads"
    static let minisWorkspaceLinuxDir = "/var/minis/workspace"
    static let minisBrowserLinuxDir = "/var/minis/browser"
    static let minisMemoryLinuxDir = "/var/minis/memory"
    static let minisSkillsLinuxDir = "/var/minis/skills"
    static let minisSharedLinuxDir = "/var/minis/shared"
    static let minisMcpServersLinuxDir = "/var/minis/mcp-servers"
    static let minisMountsLinuxDir = "/var/minis/mounts"

    static var minisPersistentBase: URL {
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return lib.appendingPathComponent("MinisChat/minis", isDirectory: true)
    }

    static func minisOffloadsPersistentDir(for sid: String) -> URL {
        minisPersistentBase.appendingPathComponent(sid, isDirectory: true)
            .appendingPathComponent("offloads", isDirectory: true)
    }

    static func minisAttachmentsPersistentDir(for sid: String) -> URL {
        minisPersistentBase.appendingPathComponent(sid, isDirectory: true)
            .appendingPathComponent("attachments", isDirectory: true)
    }

    static func minisUploadsDir(for sid: String) -> URL {
        minisAttachmentsPersistentDir(for: sid)
            .appendingPathComponent("uploads", isDirectory: true)
    }

    static func minisWorkspacePersistentDir(for sid: String) -> URL {
        minisPersistentBase.appendingPathComponent(sid, isDirectory: true)
            .appendingPathComponent("workspace", isDirectory: true)
    }

    static func minisBrowserPersistentDir(for sid: String) -> URL {
        minisPersistentBase.appendingPathComponent(sid, isDirectory: true)
            .appendingPathComponent("browser", isDirectory: true)
    }

    static var minisAppGroupRoot: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedContainerStore.appGroupID
        )!.appendingPathComponent("MinisFileProvider", isDirectory: true)
    }

    static var minisConfigRoot: URL {
        let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedContainerStore.appGroupID
        )!.appendingPathComponent("MinisConfig", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var minisMemoryPersistentDir: URL {
        minisAppGroupRoot.appendingPathComponent("memory", isDirectory: true)
    }

    static var minisSkillsPersistentDir: URL {
        minisAppGroupRoot.appendingPathComponent("skills", isDirectory: true)
    }

    static var minisSharedPersistentDir: URL {
        minisAppGroupRoot.appendingPathComponent("shared", isDirectory: true)
    }

    static var minisMcpServersPersistentDir: URL {
        minisConfigRoot.appendingPathComponent("mcp-servers", isDirectory: true)
    }
}
