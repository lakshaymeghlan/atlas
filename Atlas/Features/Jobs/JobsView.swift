import SwiftUI
import UIKit

/// Jobs tab — the match queue. Each role is a flip card (tap to see the company);
/// Pass drops it, Accept opens an optional note to the company.
struct JobsView: View {
    @Environment(JobsStore.self) private var jobs
    @State private var accepting: JobMatch?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                header
                if jobs.matches.isEmpty {
                    caughtUp
                } else {
                    ForEach(jobs.matches) { match in
                        JobCardView(
                            match: match,
                            onPass: { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { jobs.reject(match.id) } },
                            onAccept: {
                                let m = match
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { jobs.accept(match.id, note: nil) }
                                accepting = m
                            }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, Space.screen)
            .padding(.top, Space.block)
            .padding(.bottom, Space.block)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .atlasSky(height: 280, intensity: 0.8, maxClouds: 3)
        .sheet(item: $accepting) { match in
            AcceptSheet(match: match) { _ in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Eyebrow("JOBS")
            Text("Roles that\nfit you.")
                .atlasText(.display)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !jobs.matches.isEmpty {
                Text("\(jobs.matches.count) fresh matches, ranked by fit.")
                    .atlasText(.body).foregroundStyle(Palette.inkSecondary)
            }
        }
        .padding(.bottom, Space.s)
    }

    private var caughtUp: some View {
        VStack(spacing: Space.m) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
            Text("You're all caught up")
                .atlasText(.title).foregroundStyle(Palette.ink)
            Text("New matches arrive as Atlas learns more about what you want. Check back soon.")
                .atlasText(.body).foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

#Preview {
    JobsView().environment(JobsStore())
}
