import SwiftUI
import UIKit

/// The post-onboarding app shell: Jobs · Saved · Profile, with a custom bottom
/// bar styled to blend with the warm-sky surface (frosted, ink active).
struct MainTabView: View {
    var onSignOut: () -> Void

    @State private var tab: MainTab = .jobs

    var body: some View {
        ZStack {
            switch tab {
            case .jobs: HomeView()
            case .saved: SavedView()
            case .profile: ProfileView(onSignOut: onSignOut)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar(selection: $tab)
        }
    }
}

enum MainTab: CaseIterable, Identifiable {
    case jobs, saved, profile
    var id: Self { self }

    var label: String {
        switch self { case .jobs: "Jobs"; case .saved: "Saved"; case .profile: "Profile" }
    }
    var icon: String {
        switch self { case .jobs: "briefcase"; case .saved: "bookmark"; case .profile: "person" }
    }
    var iconFilled: String {
        switch self { case .jobs: "briefcase.fill"; case .saved: "bookmark.fill"; case .profile: "person.fill" }
    }
}

private struct BottomBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    guard selection != tab else { return }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selection == tab ? tab.iconFilled : tab.icon)
                            .font(.system(size: 20, weight: .regular))
                        Text(tab.label)
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? Palette.ink : Palette.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
            }
        }
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(Palette.border).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeInOut(duration: 0.18), value: selection)
    }
}

/// Saved tab — empty state for now (saving lands with the matching engine).
struct SavedView: View {
    var body: some View {
        VStack(spacing: Space.l) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            VStack(spacing: Space.s) {
                Text("Nothing saved yet")
                    .atlasText(.title).foregroundStyle(Palette.ink)
                Text("When Atlas surfaces roles that fit, save the ones you love and they'll live here.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .atlasSky(height: 300, intensity: 0.8, maxClouds: 3)
    }
}

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return MainTabView(onSignOut: {}).environment(store)
}
