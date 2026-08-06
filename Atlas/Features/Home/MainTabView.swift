import SwiftUI
import UIKit

/// The post-onboarding app shell: Jobs · Journey · Profile, with a custom bottom
/// bar styled to blend with the paper surface (frosted, ink active).
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
            case .journey: JourneyView()
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
    case jobs, journey, profile
    var id: Self { self }

    var label: String {
        switch self { case .jobs: "Jobs"; case .journey: "Journey"; case .profile: "Profile" }
    }
    var icon: String {
        switch self { case .jobs: "briefcase"; case .journey: "signpost.right"; case .profile: "person" }
    }
    var iconFilled: String {
        switch self { case .jobs: "briefcase.fill"; case .journey: "signpost.right.fill"; case .profile: "person.fill" }
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

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return MainTabView(onSignOut: {}).environment(store)
}
