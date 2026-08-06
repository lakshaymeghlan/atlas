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
                    Divider().overlay(Color.canopyPaperLine)
                    pipeline
                    prep
                }
                .padding(.horizontal, Space.l)
                .padding(.bottom, Space.l)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopyPaperDeep))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
    }

    private var header: some View {
        Button(action: toggle) {
            HStack(spacing: Space.m) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Color.canopyMist)
                    .frame(width: 44, height: 44)
                    .overlay(Text(String(app.match.company.prefix(1)))
                        .font(Typeface.display(20)).foregroundStyle(Color.canopy600))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.match.role).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        .lineLimit(1)
                    Text("\(app.match.company) · \(app.match.location)")
                        .atlasText(.caption).foregroundStyle(Color.canopy400).lineLimit(1)
                }
                Spacer(minLength: Space.s)
                VStack(alignment: .trailing, spacing: 4) {
                    stagePill
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.canopy400)
                }
            }
            .padding(Space.l)
        }
        .buttonStyle(.plain)
    }

    private var stagePill: some View {
        Text(app.stage.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.canopy900)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(Color.sun.opacity(0.35)))
            .overlay(Capsule().strokeBorder(Color.sun, lineWidth: 1))
    }

    // Vertical stepper — done stages filled, current highlighted, future muted.
    private var pipeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PipelineStage.allCases) { s in
                let done = s.rawValue < app.stage.rawValue
                let current = s == app.stage
                HStack(alignment: .center, spacing: Space.m) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(done || current ? Color.sun : Color.canopyMist)
                                .frame(width: 20, height: 20)
                            if done {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.canopy900)
                            } else if current {
                                Circle().fill(Color.canopy900).frame(width: 7, height: 7)
                            }
                        }
                        if s != PipelineStage.allCases.last {
                            Rectangle()
                                .fill(done ? Color.sun : Color.canopyPaperLine)
                                .frame(width: 2, height: 22)
                        }
                    }
                    Text(s.label)
                        .font(Typeface.body(15, weight: current ? .medium : .regular))
                        .foregroundStyle(current ? Color.canopy900 : (done ? Color.canopy600 : Color.canopy400))
                        .padding(.bottom, s != PipelineStage.allCases.last ? 22 : 0)
                    Spacer()
                }
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
