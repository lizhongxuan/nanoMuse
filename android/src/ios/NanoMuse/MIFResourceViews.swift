import SwiftUI

struct MIFResourcePageState: Equatable {
    struct ListState: Equatable {
        let isLoading: Bool
        let loadError: String?
    }

    enum DefaultTarget: Equatable {
        case unknown
        case notConfigured
        case configured(hostName: String?, workspaceName: String?)
    }

    struct Host: Equatable, Identifiable {
        enum Scope: Equatable {
            case owned
            case sharedReadOnly
        }

        enum Status: Equatable {
            case running
            case starting
            case stopping
            case stopped
            case failed
            case deleting
            case deleted
            case unknown
        }

        let id: String
        let name: String
        let scope: Scope
        let status: Status
        let workspaceSummary: String?
        let canOpen: Bool
        let control: Control?
        let error: String?
    }

    struct Control: Equatable {
        enum State: Equatable {
            case ai
            case user
            case takingOver
            case returning
            case unknown
        }

        enum Lease: Equatable {
            case none
            case active
            case expired
            case unknown
        }

        let state: State
        let lease: Lease
        let leaseExpiresAt: String?
        let transitionSummary: String?
        let isLoading: Bool
        let isActionInFlight: Bool
        let canTakeOver: Bool
        let canReturnToAI: Bool
        let canRenewLease: Bool
        let error: String?
    }

    struct Workspace: Equatable, Identifiable {
        enum Status: Equatable {
            case ready
            case syncing
            case unbound
            case unavailable
            case unknown
        }

        let id: String
        let name: String
        let status: Status
        let hostName: String?
        let isReadOnly: Bool
        let canOpenFiles: Bool
    }

    let isLoading: Bool
    let loadError: String?
    let hostsState: ListState
    let workspacesState: ListState
    let defaultTarget: DefaultTarget
    let hosts: [Host]
    let workspaces: [Workspace]
}

enum MIFResourceControlAction: String, Hashable {
    case takeOver
    case returnToAI
    case renewLease
}

enum MIFResourcePageSection: CaseIterable, Hashable {
    case cloudComputers
    case cloudPhones
    case workspaces
    case aiTools

    var title: String {
        switch self {
        case .cloudComputers: return AppLocalized("Cloud computers")
        case .cloudPhones: return AppLocalized("Cloud phones")
        case .workspaces: return AppLocalized("Workspaces")
        case .aiTools: return AppLocalized("AI tools")
        }
    }

    var emptyMessage: String {
        switch self {
        case .cloudComputers: return AppLocalized("No cloud computers are available in this account scope.")
        case .cloudPhones: return AppLocalized("Execution status unavailable")
        case .workspaces: return AppLocalized("No Workspaces are available in this account scope.")
        case .aiTools: return AppLocalized("No AI tool runtime status is available in this account scope.")
        }
    }

    var emptySymbol: String {
        switch self {
        case .cloudComputers: return "desktopcomputer"
        case .cloudPhones: return "iphone"
        case .workspaces: return "externaldrive"
        case .aiTools: return "wrench.and.screwdriver"
        }
    }

    var emptyStateIdentifier: String {
        switch self {
        case .cloudComputers: return "morde.resources.empty.cloudComputers"
        case .cloudPhones: return "morde.resources.empty.cloudPhones"
        case .workspaces: return "morde.resources.empty.workspaces"
        case .aiTools: return "morde.resources.empty.aiTools"
        }
    }
}

enum MIFResourcePageRules {
    static func showsEmptyState(for section: MIFResourcePageSection,
                                state: MIFResourcePageState) -> Bool {
        switch section {
        case .cloudComputers:
            return state.hosts.isEmpty && !state.hostsState.isLoading && state.hostsState.loadError == nil
        case .workspaces:
            return state.workspaces.isEmpty && !state.workspacesState.isLoading && state.workspacesState.loadError == nil
        case .cloudPhones, .aiTools:
            return true
        }
    }

    static func controlActions(for host: MIFResourcePageState.Host) -> [MIFResourceControlAction] {
        guard host.scope == .owned, host.status == .running, let control = host.control,
              !control.isLoading, !control.isActionInFlight,
              control.transitionSummary == nil, control.state == .user,
              control.canReturnToAI,
              control.lease == .active || control.lease == .expired else { return [] }

        return [.returnToAI]
    }
}

struct MIFResourcePageActions {
    let refresh: () async -> Void
    let openLibrary: () -> Void
    let addResource: (() -> Void)? = nil
    let openHost: (MIFResourcePageState.Host) -> Void
    let shareHost: (String) -> Void
    let refreshControl: (String) -> Void
    let control: (String, MIFResourceControlAction) -> Void
    let openWorkspaceFiles: (String) -> Void
}

@MainActor
struct MIFResourceRoom: View {
    var chrome: NanoMuseRoomChrome? = nil
    var onMenu: (() -> Void)? = nil
    let state: MIFResourcePageState
    let actions: MIFResourcePageActions
    @Environment(\.dismiss) private var dismiss
    @State private var resourceToast: String?
    @State private var resourceToastID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            if let onMenu {
                designHeader(onMenu: onMenu)
            } else if let chrome {
                NanoMuseRoomHeader(chrome: chrome) {
                    addResourceButton
                }
            } else {
                NanoMuseTopBar(title: AppLocalized("Resources"), onBack: { dismiss() }) {
                    addResourceButton
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if state.isLoading && state.hosts.isEmpty && state.workspaces.isEmpty {
                        ProgressView(AppLocalized("Loading resources…"))
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                    if let loadError = state.loadError {
                        statusRow(loadError, symbol: "exclamationmark.triangle")
                    }
                    ForEach(MIFResourcePageSection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 0) {
                            if section != .cloudPhones {
                                sectionTitle(section.title)
                                    .padding(.top, section == .cloudComputers ? 8 : 24)
                                    .padding(.bottom, 2)
                            }
                            sectionContent(section)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 2)
                .padding(.bottom, 24)
                .mordeVerticalScrollBounceProbe()
            }
            .refreshable {
                // Keep the list fetch alive if SwiftUI cancels the pull gesture task.
                let refreshTask = Task { await actions.refresh() }
                await refreshTask.value
            }
            .mordeAlwaysBounceVertically()
            .accessibilityIdentifier("morde.resources.scroll")
        }
        .background(NanoMuseTones.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let resourceToast {
                Text(resourceToast)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.82), in: Capsule())
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("morde.resources.add.unavailable")
                    .transition(.opacity)
            }
        }
    }

    private func designHeader(onMenu: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button(action: onMenu) {
                VStack(spacing: 3.1) {
                    Capsule().frame(width: 12.7, height: 1.66)
                    Capsule().frame(width: 12.7, height: 1.66)
                }
                .foregroundStyle(NanoMuseTones.ink)
                .frame(width: 38, height: 38)
                .background(NanoMuseTones.surface, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLocalized("Chats and settings")))
            .accessibilityIdentifier("morde.nav.menu")

            Text(AppLocalized("Resources"))
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.17)
                .lineLimit(1)

            Spacer(minLength: 8)
            addResourceButton
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .frame(minHeight: 52)
    }

    private var addResourceButton: some View {
        Button {
            if let addResource = actions.addResource {
                addResource()
            } else {
                let id = UUID()
                resourceToastID = id
                withAnimation { resourceToast = AppLocalized("Not implemented yet") }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                    guard resourceToastID == id else { return }
                    withAnimation { resourceToast = nil }
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(NanoMuseTones.ink)
                .frame(width: 38, height: 38)
                .background(NanoMuseTones.surface, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AppLocalized("Add resource")))
        .accessibilityIdentifier("morde.resources.add")
    }

    @ViewBuilder
    private func sectionContent(_ section: MIFResourcePageSection) -> some View {
        switch section {
        case .cloudComputers:
            if state.hosts.isEmpty, MIFResourcePageRules.showsEmptyState(for: section, state: state) {
                statusRow(section.emptyMessage, symbol: section.emptySymbol)
                    .accessibilityIdentifier(section.emptyStateIdentifier)
            } else if state.hosts.isEmpty {
                EmptyView()
            } else {
                ForEach(state.hosts) { host in
                    hostRow(host)
                }
            }
        case .cloudPhones, .aiTools:
            statusRow(section.emptyMessage, symbol: section.emptySymbol)
                .accessibilityIdentifier(section.emptyStateIdentifier)
        case .workspaces:
            if state.workspaces.isEmpty, MIFResourcePageRules.showsEmptyState(for: section, state: state) {
                statusRow(section.emptyMessage, symbol: section.emptySymbol)
                    .accessibilityIdentifier(section.emptyStateIdentifier)
            } else if state.workspaces.isEmpty {
                EmptyView()
            } else {
                ForEach(state.workspaces) { workspace in
                    workspaceRow(workspace)
                }
            }
        }
    }

    private func hostRow(_ host: MIFResourcePageState.Host) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                actions.openHost(host)
            } label: {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 20))
                        .foregroundStyle(NanoMuseTones.ink)
                        .frame(width: 44, height: 44)
                        .background(NanoMuseTones.fill, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(host.name)
                            .font(.system(size: 16, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        if let workspaceSummary = host.workspaceSummary, !workspaceSummary.isEmpty {
                            Text(workspaceSummary)
                                .font(.system(size: 14))
                                .foregroundStyle(NanoMuseTones.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 6) {
                            Text(host.status.localizedTitle)
                                .accessibilityIdentifier("morde.resources.host.status.\(host.id)")
                            if host.scope == .sharedReadOnly {
                                Text("·")
                                Text(AppLocalized("Shared read-only"))
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(NanoMuseTones.secondaryText)

                        if host.scope == .owned { controlStatus(host) }
                        if host.status == .running && !host.canOpen && host.scope == .owned {
                            Text(AppLocalized("A ready Workspace binding is required to open this computer."))
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                        } else if host.scope == .sharedReadOnly && host.status == .running && !host.canOpen {
                            Text(AppLocalized("You do not have permission to view this computer."))
                                .font(.footnote)
                                .foregroundStyle(NanoMuseTones.secondaryText)
                        }
                        if let error = host.error {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .accessibilityIdentifier("morde.resources.host.error.\(host.id)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if host.canOpen {
                        resourceDisclosureChevron
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!host.canOpen)
            .accessibilityIdentifier("morde.resources.host.open.\(host.id)")

            VStack(spacing: 4) {
                if MIFResourcePageRules.controlActions(for: host).contains(.returnToAI) {
                    Button {
                        actions.control(host.id, .returnToAI)
                    } label: {
                        Image(systemName: MIFResourceControlAction.returnToAI.systemImage)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text(MIFResourceControlAction.returnToAI.localizedTitle))
                    .accessibilityIdentifier("morde.resources.host.returnToAI.\(host.id)")
                } else if host.control?.isLoading == true || host.control?.isActionInFlight == true {
                    ProgressView().controlSize(.small)
                        .accessibilityLabel(Text(AppLocalized("Updating control status")))
                }
            }
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("morde.resources.host.\(host.id)")
        .contextMenu {
            if host.scope == .owned && host.status != .deleting && host.status != .deleted {
                Button {
                    actions.shareHost(host.id)
                } label: {
                    Label(AppLocalized("Share control"), systemImage: "person.crop.circle.badge.plus")
                }
                .accessibilityIdentifier("morde.resources.host.share.\(host.id)")
            }
        }
    }

    @ViewBuilder
    private func controlStatus(_ host: MIFResourcePageState.Host) -> some View {
        if let control = host.control {
            VStack(alignment: .leading, spacing: 4) {
                Label(control.state.localizedTitle, systemImage: "lock.shield")
                .font(.caption.weight(.medium))
                if control.lease != .none {
                    Text(control.lease.localizedTitle)
                        .font(.footnote)
                        .foregroundStyle(control.lease == .expired || control.lease == .unknown ? Color.orange : Color.secondary)
                }
                if let expiresAt = control.leaseExpiresAt, control.lease == .active {
                    Text(String(format: AppLocalized("Lease expires %@"), expiresAt))
                        .font(.caption)
                        .foregroundStyle(NanoMuseTones.secondaryText)
                }
                if let transitionSummary = control.transitionSummary {
                    Text(transitionSummary)
                        .font(.caption)
                        .foregroundStyle(NanoMuseTones.secondaryText)
                        .accessibilityIdentifier("morde.resources.host.transition.\(host.id)")
                }
                if let error = control.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        } else {
            Text(AppLocalized("Control status unknown; control actions are disabled."))
                .font(.footnote)
                .foregroundStyle(.orange)
        }
    }

    private func workspaceRow(_ workspace: MIFResourcePageState.Workspace) -> some View {
        let hostName = workspace.hostName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isMounted = workspace.status == .ready && hostName?.isEmpty == false
        return Button {
            actions.openWorkspaceFiles(workspace.id)
        } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 21))
                    .foregroundStyle(NanoMuseTones.ink)
                    .frame(width: 44, height: 44)
                    .background(NanoMuseTones.fill, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(workspace.name)
                        .font(.system(size: 16, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(isMounted ? AppLocalized("Mounted") : workspace.status.localizedTitle)
                        if let hostName, !hostName.isEmpty {
                            Text("·")
                            Text(hostName)
                        }
                        if workspace.isReadOnly {
                            Text("·")
                            Text(AppLocalized("Read-only"))
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(NanoMuseTones.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if workspace.canOpenFiles {
                    resourceDisclosureChevron
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!workspace.canOpenFiles)
        .accessibilityIdentifier("morde.resources.workspace.open.\(workspace.id)")
        .padding(.vertical, 13)
    }

    private var resourceDisclosureChevron: some View {
        Text("›")
            .font(.system(size: 20, weight: .light))
            .foregroundStyle(Color(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 203.0 / 255.0))
            .padding(.top, 9)
            .accessibilityHidden(true)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
    }

    private func statusRow(_ message: String, symbol: String) -> some View {
        Label {
            Text(message)
                .font(.footnote)
                .foregroundStyle(NanoMuseTones.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(NanoMuseTones.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("morde.resources.loadError")
    }
}

private extension MIFResourcePageState.Host.Status {
    var localizedTitle: String {
        switch self {
        case .running: return AppLocalized("Running")
        case .starting: return AppLocalized("Starting")
        case .stopping: return AppLocalized("Stopping")
        case .stopped: return AppLocalized("Stopped")
        case .failed: return AppLocalized("Failed")
        case .deleting: return AppLocalized("Deleting")
        case .deleted: return AppLocalized("Deleted")
        case .unknown: return AppLocalized("Status unknown")
        }
    }
}

private extension MIFResourcePageState.Control.State {
    var localizedTitle: String {
        switch self {
        case .ai: return AppLocalized("AI controls this computer")
        case .user: return AppLocalized("You control this computer")
        case .takingOver: return AppLocalized("Control handoff in progress")
        case .returning: return AppLocalized("Returning control to AI")
        case .unknown: return AppLocalized("Control status unknown")
        }
    }
}

private extension MIFResourcePageState.Control.Lease {
    var localizedTitle: String {
        switch self {
        case .none: return AppLocalized("No active control lease")
        case .active: return AppLocalized("Control lease active")
        case .expired: return AppLocalized("Control lease expired")
        case .unknown: return AppLocalized("Lease status unknown")
        }
    }
}

private extension MIFResourcePageState.Workspace.Status {
    var localizedTitle: String {
        switch self {
        case .ready: return AppLocalized("Ready")
        case .syncing: return AppLocalized("Syncing")
        case .unbound: return AppLocalized("Not mounted")
        case .unavailable: return AppLocalized("Unavailable")
        case .unknown: return AppLocalized("Status unknown")
        }
    }
}

private extension MIFResourceControlAction {
    var localizedTitle: String {
        switch self {
        case .takeOver: return AppLocalized("Take control")
        case .returnToAI: return AppLocalized("Return control to AI")
        case .renewLease: return AppLocalized("Renew lease")
        }
    }

    var systemImage: String {
        switch self {
        case .takeOver: return "hand.raised"
        case .returnToAI: return "arrow.uturn.backward"
        case .renewLease: return "clock.arrow.circlepath"
        }
    }
}
