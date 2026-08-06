import SwiftUI
import UIKit

/// The post-onboarding app shell: Jobs · Saved · Profile, with a custom bottom
/// bar styled to blend with the warm-sky surface (frosted, ink active).
struct MainTabView: View {
    var onSignOut: () -> Void

    @State private var tab: MainTab = .jobs
    @State private var jobs = JobsStore()

    var body: some View {
        ZStack {
            // One paper surface (with grain) behind every tab, so each tab's
            // content respects the safe area without fighting per-tab backgrounds.
            Color.canopyPaper.ignoresSafeArea().canopyGrain()

            switch tab {
            case .jobs: JobsView()
            case .saved: SavedView()
            case .profile: ProfileView(onSignOut: onSignOut)
            }
        }
        .environment(jobs)
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
                    .foregroundStyle(selection == tab ? Color.canopy900 : Color.canopy400)
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
                    Rectangle().fill(Color.canopyPaperLine).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeInOut(duration: 0.18), value: selection)
    }
}

/// Saved tab — the roles you bookmarked from the Jobs deck.
struct SavedView: View {
    @Environment(JobsStore.self) private var jobs

    var body: some View {
        Group {
            if jobs.saved.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.l) {
                        HStack {
                            Eyebrow("SAVED")
                            Spacer()
                            Text("\(jobs.saved.count) saved").atlasText(.meta).foregroundStyle(Color.canopy400)
                        }
                        ForEach(jobs.saved) { match in savedCard(match) }
                    }
                    .padding(.horizontal, Space.screen)
                    .padding(.top, Space.block)
                    .padding(.bottom, Space.block)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func savedCard(_ match: JobMatch) -> some View {
        AtlasCard(padding: Space.l) {
            VStack(alignment: .leading, spacing: Space.m) {
                HStack(alignment: .top, spacing: Space.m) {
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(Color.canopyMist)
                        .frame(width: 40, height: 40)
                        .overlay(Text(String(match.company.prefix(1)))
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.canopy600))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.role).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        Text("\(match.company) · \(match.location)")
                            .atlasText(.caption).foregroundStyle(Color.canopy600)
                    }
                    Spacer(minLength: Space.s)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { jobs.toggleSave(match) }
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15)).foregroundStyle(Color.canopy600)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Remove from saved")
                }
                if let salary = match.salary {
                    Text("\(match.match)% match · \(salary)")
                        .atlasText(.caption).foregroundStyle(Color.canopy400)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Space.m) {
            Image(systemName: "bookmark")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color.canopy400)
            Text("Nothing saved yet")
                .atlasText(.title).foregroundStyle(Color.canopy900)
            Text("Tap the bookmark on a role in Jobs to keep it here for later.")
                .atlasText(.body)
                .foregroundStyle(Color.canopy600)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(.horizontal, Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return MainTabView(onSignOut: {}).environment(store)
}
