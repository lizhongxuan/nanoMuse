import SwiftUI
import UIKit

enum MordeDesignTab: String, CaseIterable, Hashable, Identifiable {
    case chat
    case tasks
    case approvals
    case resources

    var id: String { rawValue }

    var route: MordeDesignRoute {
        switch self {
        case .chat: .chat
        case .tasks: .tasks
        case .approvals: .approvals
        case .resources: .resources
        }
    }

    var title: String {
        switch self {
        case .chat: AppLocalized("Chat")
        case .tasks: AppLocalized("Tasks")
        case .approvals: AppLocalized("Approvals")
        case .resources: AppLocalized("Resources")
        }
    }

    var symbol: String {
        switch self {
        case .chat: "bubble.left"
        case .tasks: "checkmark.square"
        case .approvals: "checkmark.shield"
        case .resources: "square.grid.2x2"
        }
    }
}

enum MordeDesignRoute: Hashable {
    case chat
    case tasks
    case approvals
    case eventChain
    case resources
    case library
    case workItems
    case friends
    case toolChats
    case settings
    case settingsDetail(String)
    case search
    case chatConversation(String)
    case task(String)
    case workspace(String)
    case computer(String, shared: Bool)
    case file(String)

    var primaryTab: MordeDesignTab? {
        switch self {
        case .chat, .chatConversation: .chat
        case .tasks, .eventChain, .workItems, .task: .tasks
        case .approvals: .approvals
        case .resources, .library, .workspace, .computer, .file: .resources
        case .friends, .toolChats, .settings, .settingsDetail, .search: nil
        }
    }

    var hidesBottomBar: Bool {
        if case .computer = self { return true }
        return false
    }
}

enum MIFDrawerDestination: String, CaseIterable, Identifiable {
    case chat, tasks, approvals, eventChain, resources, library, workItems, friends, toolChats

    var id: String { rawValue }

    var route: MordeDesignRoute {
        switch self {
        case .chat: .chat
        case .tasks: .tasks
        case .approvals: .approvals
        case .eventChain: .eventChain
        case .resources: .resources
        case .library: .library
        case .workItems: .workItems
        case .friends: .friends
        case .toolChats: .toolChats
        }
    }
}

struct MordeDesignDrawerItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let route: MordeDesignRoute
    var badge: Int? = nil
    var isSelected = false

    init(id: String, title: String, systemImage: String, route: MordeDesignRoute,
         badge: Int? = nil, isSelected: Bool = false) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.route = route
        self.badge = badge
        self.isSelected = isSelected
    }
}

struct MordeDesignDrawerSection: Identifiable {
    let id: String
    let title: String?
    let hint: String?
    let items: [MordeDesignDrawerItem]
    let emptyMessage: String?

    init(id: String, title: String? = nil, hint: String? = nil,
         items: [MordeDesignDrawerItem], emptyMessage: String? = nil) {
        self.id = id
        self.title = title
        self.hint = hint
        self.items = items
        self.emptyMessage = emptyMessage
    }
}

struct MordeDesignDrawerFooter {
    let settingsTitle: String
    let searchPlaceholder: String
    let newChatTitle: String

    init(settingsTitle: String, searchPlaceholder: String, newChatTitle: String) {
        self.settingsTitle = settingsTitle
        self.searchPlaceholder = searchPlaceholder
        self.newChatTitle = newChatTitle
    }
}

struct MordeDesignNavigationShell<Content: View>: View {
    private let selectedRoute: MordeDesignRoute
    private let selectedTab: MordeDesignTab
    private let approvalCount: Int?
    private let brandTitle: String
    private let drawerSections: [MordeDesignDrawerSection]
    private let footer: MordeDesignDrawerFooter
    @Binding private var searchText: String
    private let onSelectTab: (MordeDesignTab) -> Void
    private let onSelectRoute: (MordeDesignRoute) -> Void
    private let onSettings: () -> Void
    private let onNewChat: () -> Void
    private let onOpenDrawer: () -> Void
    private let onDrawerItemAppear: (MordeDesignRoute) -> Void
    private let content: (MordeDesignRoute, @escaping () -> Void) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDrawerOpen = false

    init(selectedRoute: MordeDesignRoute, selectedTab: MordeDesignTab, approvalCount: Int?,
         brandTitle: String = "Morde", drawerSections: [MordeDesignDrawerSection],
         footer: MordeDesignDrawerFooter, searchText: Binding<String>,
         onSelectTab: @escaping (MordeDesignTab) -> Void,
         onSelectRoute: @escaping (MordeDesignRoute) -> Void,
         onSettings: @escaping () -> Void,
         onNewChat: @escaping () -> Void, onOpenDrawer: @escaping () -> Void = {},
         onDrawerItemAppear: @escaping (MordeDesignRoute) -> Void = { _ in },
         @ViewBuilder content: @escaping (MordeDesignRoute, @escaping () -> Void) -> Content) {
        self.selectedRoute = selectedRoute
        self.selectedTab = selectedTab
        self.approvalCount = approvalCount
        self.brandTitle = brandTitle
        self.drawerSections = drawerSections
        self.footer = footer
        self._searchText = searchText
        self.onSelectTab = onSelectTab
        self.onSelectRoute = onSelectRoute
        self.onSettings = onSettings
        self.onNewChat = onNewChat
        self.onOpenDrawer = onOpenDrawer
        self.onDrawerItemAppear = onDrawerItemAppear
        self.content = content
    }

    var body: some View {
        ZStack {
            routedContent
            if isDrawerOpen { drawerOverlay.zIndex(2) }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isDrawerOpen)
    }

    @ViewBuilder
    private var routedContent: some View {
        if selectedRoute.hidesBottomBar {
            content(selectedRoute, openDrawer)
        } else {
            content(selectedRoute, openDrawer)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .background(Color.clear)
                }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 2) {
            ForEach(MordeDesignTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(5)
        .frame(height: 62)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
    }

    private func tabButton(_ tab: MordeDesignTab) -> some View {
        let isSelected = selectedTab == tab
        return Button { onSelectTab(tab) } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 22, weight: .regular))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Capsule())
                if tab == .approvals, let approvalCount, approvalCount > 0 {
                    Text(approvalCount > 99 ? "99+" : String(approvalCount))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(Color.red, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color(uiColor: .systemBackground), lineWidth: 2))
                        .offset(x: -8, y: 2)
                }
            }
            .foregroundStyle(Color.primary)
            .background(isSelected ? Color.primary.opacity(0.08) : Color.clear, in: Capsule())
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tab.title))
        .accessibilityValue(isSelected ? Text("Selected") : Text(""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("morde.nav.tab.\(tab.id)")
    }

    private var drawerOverlay: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Button(action: closeDrawer) {
                    Color.black.opacity(0.28)
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close navigation menu"))
                .accessibilityIdentifier("morde.nav.drawer.scrim")

                drawerPanel(width: min(geometry.size.width * 0.86, 322),
                            topInset: geometry.safeAreaInsets.top,
                            bottomInset: geometry.safeAreaInsets.bottom)
                    .frame(width: min(geometry.size.width * 0.86, 322))
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .leading))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .ignoresSafeArea()
        }
    }

    private func drawerPanel(width: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(brandTitle)
                        .font(.system(size: 26, weight: .heavy))
                        .tracking(-0.5)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                    ForEach(displayedDrawerSections) { section in
                        drawerSection(section)
                    }
                }
                .padding(.top, max(64, topInset + 16))
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("morde.nav.drawer.scroll")

            drawerFooter(bottomInset: bottomInset)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .clipShape(MordeDrawerShape())
        .shadow(color: .black.opacity(0.16), radius: 24, x: 12, y: 0)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("morde.nav.drawer")
    }

    @ViewBuilder
    private func drawerSection(_ section: MordeDesignDrawerSection) -> some View {
        if let title = section.title {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 18)
        }
        if let hint = section.hint {
            Text(hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 5)
        }
        if !section.items.isEmpty {
            LazyVStack(spacing: 2) {
                ForEach(section.items) { item in
                    drawerRow(item)
                }
            }
            .padding(.top, 10)
        } else if let emptyMessage = section.emptyMessage {
            Text(emptyMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        if section.id != drawerSections.last?.id {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 12)
                .padding(.top, 16)
        }
    }

    private func drawerRow(_ item: MordeDesignDrawerItem) -> some View {
        Button {
            closeDrawer()
            onSelectRoute(item.route)
        } label: {
            HStack(spacing: 13) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 22, weight: .regular))
                    .frame(width: 24)
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let badge = item.badge, badge > 0 {
                    Text(badge > 99 ? "99+" : String(badge))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 19, minHeight: 19)
                        .background(Color.red, in: Capsule())
                }
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .contentShape(Capsule())
            .background(item.isSelected ? Color.primary.opacity(0.08) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.title))
        .accessibilityValue(item.badge.map { Text(String($0)) } ?? Text(""))
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
        .accessibilityIdentifier("morde.nav.drawer.\(item.id)")
        .onAppear {
            if case .chatConversation = item.route { onDrawerItemAppear(item.route) }
        }
    }

    private func drawerFooter(bottomInset: CGFloat) -> some View {
        HStack(spacing: 9) {
            NanoMuseRoundButton(symbol: "gearshape", label: footer.settingsTitle, size: 38,
                                accessibilityIdentifier: "morde.nav.drawer.settings") {
                closeDrawer()
                onSettings()
            }

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                TextField(footer.searchPlaceholder, text: $searchText)
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel(Text(footer.searchPlaceholder))
                    .accessibilityIdentifier("morde.nav.drawer.search")
            }
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Color(uiColor: .systemBackground), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("morde.nav.drawer.search.container")

            NanoMuseRoundButton(symbol: "square.and.pencil", label: footer.newChatTitle, size: 38,
                                accessibilityIdentifier: "morde.nav.drawer.newChat") {
                closeDrawer()
                onNewChat()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, max(20, bottomInset + 8))
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func openDrawer() {
        onOpenDrawer()
        if reduceMotion { isDrawerOpen = true }
        else { withAnimation(.easeInOut(duration: 0.3)) { isDrawerOpen = true } }
    }

    private func closeDrawer() {
        if reduceMotion { isDrawerOpen = false }
        else { withAnimation(.easeInOut(duration: 0.3)) { isDrawerOpen = false } }
    }

    private var displayedDrawerSections: [MordeDesignDrawerSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return drawerSections }
        return drawerSections.map { section in
            guard section.id == "conversations" else { return section }
            let items = section.items.filter { $0.title.localizedCaseInsensitiveContains(query) }
            return MordeDesignDrawerSection(
                id: section.id, title: section.title, hint: section.hint, items: items,
                emptyMessage: items.isEmpty ? AppLocalized("No chats found") : section.emptyMessage)
        }
    }
}

private struct MordeDrawerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 26
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct NanoMuseRoomChrome {
    var liveId: String?
    var name: String
    var hasMainSession: Bool
    var onMenu: () -> Void
    var onBack: (() -> Void)?
    var showsLibraryShortcuts: Bool
    var onOpenPage: ((String) -> Void)?

    init(liveId: String? = nil, name: String = "Morde", hasMainSession: Bool = false,
         onMenu: @escaping () -> Void, onBack: (() -> Void)? = nil,
         showsLibraryShortcuts: Bool = false, onOpenPage: ((String) -> Void)? = nil) {
        self.liveId = liveId
        self.name = name
        self.hasMainSession = hasMainSession
        self.onMenu = onMenu
        self.onBack = onBack
        self.showsLibraryShortcuts = showsLibraryShortcuts
        self.onOpenPage = onOpenPage
    }

    func open(_ page: String) { onOpenPage?(page) }
}

struct NanoMuseRoomHeader<Trailing: View>: View {
    var chrome: NanoMuseRoomChrome
    @ViewBuilder var trailing: () -> Trailing

    init(chrome: NanoMuseRoomChrome, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.chrome = chrome
        self.trailing = trailing
    }

    var body: some View {
        MordeDesignPageHeader(title: chrome.name, onMenu: chrome.onMenu, trailing: trailing)
    }
}
