import SwiftUI
import UIKit

/// Journey tab — where each application stands. One expandable row per company:
/// collapsed shows the current stage; expanded reveals the full pipeline and
/// "what they'll ask" so you know what to study.
struct JourneyView: View {
    @Environment(JobsStore.self) private var jobs
    @State private var expanded: UUID?

    var body: some View {
        Group {
            if jobs.applications.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.m) {
                        header
                        ForEach(jobs.applications) { app in
                            JourneyCard(app: app,
                                        isOpen: expanded == app.id,
                                        toggle: { toggle(app.id) })
                        }
                    }
                    .padding(.horizontal, Space.screen)
                    .padding(.top, Space.block)
                    .padding(.bottom, Space.block)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Eyebrow("YOUR JOURNEY")
            Text("Where you\nstand.")
                .atlasText(.display).foregroundStyle(Color.canopy900)
                .fixedSize(horizontal: false, vertical: true)
            Text("Every company you're talking to, and what to prep next.")
                .atlasText(.body).foregroundStyle(Color.canopy600)
        }
        .padding(.bottom, Space.s)
    }

    private func toggle(_ id: UUID) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            expanded = expanded == id ? nil : id
        }
    }

    private var emptyState: some View {
        VStack(spacing: Space.m) {
            Image(systemName: "signpost.right")
                .font(.system(size: 34, weight: .light)).foregroundStyle(Color.canopy400)
            Text("No applications yet").atlasText(.title).foregroundStyle(Color.canopy900)
            Text("Accept a role in Jobs and it'll show up here — with its interview stages and what to study.")
                .atlasText(.body).foregroundStyle(Color.canopy600)
                .multilineTextAlignment(.center).frame(maxWidth: 300)
        }
        .padding(.horizontal, Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct JourneyCard: View {
    let app: Application
    let isOpen: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if isOpen {
                VStack(alignment: .leading, spacing: Space.l) {
                    pipeline
                    prep
                }
                .padding(Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.canopyPaperDeep)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
    }

    // Dark header — the "blend": navy top, light body when expanded.
    private var header: some View {
        Button(action: toggle) {
            HStack(spacing: Space.m) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Color.canopyPaper.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(Text(String(app.match.company.prefix(1)))
                        .font(Typeface.display(20)).foregroundStyle(Color.canopyPaper))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.match.role).atlasText(.bodyStrong).foregroundStyle(Color.canopyPaper)
                        .lineLimit(1)
                    Text("\(app.match.company) · \(app.match.location)")
                        .atlasText(.caption).foregroundStyle(Color.canopy200).lineLimit(1)
                }
                Spacer(minLength: Space.s)
                VStack(alignment: .trailing, spacing: 6) {
                    stagePill
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.canopy200)
                }
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity)
            .background(Color.canopy900)
        }
        .buttonStyle(.plain)
    }

    private var stagePill: some View {
        Text(app.stage.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.canopy900)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(Color.sun))
    }

    // Horizontal tracker — order-tracking style. Line fills amber to the current
    // stage; done stages get a check, current gets a ring, future are muted.
    private var pipeline: some View {
        let current = app.stage.rawValue
        let stages = PipelineStage.allCases
        return VStack(alignment: .leading, spacing: Space.s) {
            Text("Stage \(current + 1) of \(stages.count) · \(app.stage.label)")
                .atlasText(.caption).foregroundStyle(Color.canopy600)
            HStack(spacing: 0) {
                ForEach(stages) { s in
                    let i = s.rawValue
                    VStack(spacing: 7) {
                        ZStack {
                            HStack(spacing: 0) {
                                connector(filled: i <= current, hidden: i == 0)       // left half
                                connector(filled: i < current, hidden: i == stages.count - 1) // right half
                            }
                            node(i: i, current: current)
                        }
                        .frame(height: 22)
                        Text(s.short)
                            .font(.system(size: 9.5, weight: i == current ? .semibold : .regular))
                            .foregroundStyle(i == current ? Color.canopy900 : (i < current ? Color.canopy600 : Color.canopy400))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func connector(filled: Bool, hidden: Bool) -> some View {
        Rectangle()
            .fill(hidden ? Color.clear : (filled ? Color.sun : Color.canopyPaperLine))
            .frame(height: 2)
    }

    @ViewBuilder private func node(i: Int, current: Int) -> some View {
        let done = i < current
        let isCurrent = i == current
        ZStack {
            Circle().fill(done || isCurrent ? Color.sun : Color.canopyMist)
                .frame(width: isCurrent ? 22 : 18, height: isCurrent ? 22 : 18)
            if isCurrent {
                Circle().strokeBorder(Color.canopy900, lineWidth: 2).frame(width: 22, height: 22)
            }
            if done {
                Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.canopy900)
            }
        }
    }

    private var prep: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("WHAT THEY'LL ASK")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.5).foregroundStyle(Color.canopy400)
            Text("So you know what to study before your next round.")
                .atlasText(.caption).foregroundStyle(Color.canopy600)
            FlowLayout(spacing: Space.s) {
                ForEach(app.match.prepTopics, id: \.self) { topic in
                    Text(topic)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.canopy900)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(Color.canopyMist))
                }
            }
        }
    }
}
