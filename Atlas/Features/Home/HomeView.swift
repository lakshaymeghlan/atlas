import SwiftUI

/// Home — the landing dashboard. A dark greeting hero, a live "Canopy
/// understands you" confidence card (scored from how complete the profile is,
/// naming what's missing), a matches banner (not the full deck), educational
/// metric tiles, and an "up next" prep nudge. Deep-links via `goTo`.
struct HomeView: View {
    var goTo: (MainTab) -> Void

    @Environment(JobsStore.self) private var jobs
    @Environment(ProfileStore.self) private var profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.block) {
                greeting
                confidenceCard
                matchesBanner
                metricsGrid
                if let up = furthestApplication { upNext(up) }
            }
            .padding(.horizontal, Space.screen)
            .padding(.top, Space.block)
            .padding(.bottom, Space.block)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var firstName: String {
        profile.profile.fullName?.split(separator: " ").first.map(String.init) ?? "there"
    }

    // MARK: Greeting hero (dark)

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("WELCOME BACK")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.6).foregroundStyle(Color.canopy200)
            Text("Hi \(firstName).")
                .atlasText(.display).foregroundStyle(Color.canopyPaper)
            Text("Here's where things stand today.")
                .atlasText(.body).foregroundStyle(Color.canopy200)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous).fill(Color.canopy900))
    }

    // MARK: Canopy understands you (confidence)

    private var confidenceCard: some View {
        let score = confidence
        let missing = signals.filter { !$0.present }
        return VStack(alignment: .leading, spacing: Space.l) {
            HStack(spacing: Space.l) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CANOPY UNDERSTANDS YOU")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(1.3).foregroundStyle(Color.canopy400)
                    Text("\(score)% profile confidence")
                        .font(Typeface.display(22)).foregroundStyle(Color.canopy900)
                    Text(missing.isEmpty
                         ? "Your profile is complete — matches are dialled in."
                         : "\(countWord(missing.count)) could improve your recommendations.")
                        .atlasText(.caption).foregroundStyle(Color.canopy600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Space.s)
                ConfidenceRing(progress: Double(score) / 100)
            }
            if !missing.isEmpty {
                FlowLayout(spacing: Space.s) {
                    ForEach(missing.prefix(3), id: \.action) { s in
                        Button { goTo(.profile) } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                                Text(s.action).font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.canopy600)
                            .padding(.horizontal, 11).padding(.vertical, 7)
                            .background(Capsule().fill(Color.canopyMist))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopyPaperDeep))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
    }

    // MARK: Matches banner (not the full list)

    private var matchesBanner: some View {
        Button { goTo(.explore) } label: {
            HStack(spacing: Space.m) {
                ZStack {
                    Circle().fill(Color.sun.opacity(0.22)).frame(width: 46, height: 46)
                    Image(systemName: "sparkles").font(.system(size: 20)).foregroundStyle(Color.sunDeep)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(jobs.matches.isEmpty ? "No new roles right now" : "\(jobs.matches.count) roles match you right now")
                        .atlasText(.bodyStrong).foregroundStyle(Color.canopyPaper)
                    Text(jobs.matches.isEmpty ? "We'll let you know when new ones land" : "Swipe through them in Explore")
                        .atlasText(.caption).foregroundStyle(Color.canopy200)
                }
                Spacer(minLength: Space.s)
                Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.canopy200)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopy900))
        }
        .buttonStyle(.plain)
        .disabled(jobs.matches.isEmpty)
    }

    // MARK: Metric tiles

    private var metricsGrid: some View {
        let cols = [GridItem(.flexible(), spacing: Space.m), GridItem(.flexible(), spacing: Space.m)]
        return LazyVGrid(columns: cols, spacing: Space.m) {
            tile("Top match", topMatch > 0 ? "\(topMatch)%" : "—", "rosette", accent: true)
            tile("Avg fit", avgMatch > 0 ? "\(avgMatch)%" : "—", "chart.bar")
            tile("In pipeline", "\(jobs.applications.count)", "signpost.right")
            tile("Interviewing", "\(interviewingCount)", "person.wave.2")
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Image(systemName: icon).font(.system(size: 15))
                .foregroundStyle(accent ? Color.sunDeep : Color.canopy400)
            Text(value).font(.system(size: 26, weight: .bold)).foregroundStyle(Color.canopy900)
            Text(label).atlasText(.caption).foregroundStyle(Color.canopy400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.l)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopyPaperDeep))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
    }

    // MARK: Up next (prep nudge)

    private func upNext(_ app: Application) -> some View {
        Button { goTo(.journey) } label: {
            VStack(alignment: .leading, spacing: Space.m) {
                HStack {
                    Text("UP NEXT").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(1.3).foregroundStyle(Color.canopy400)
                    Spacer()
                    Text(app.stage.label).font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.canopy900)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule().fill(Color.sun))
                }
                Text("\(app.match.role) · \(app.match.company)")
                    .atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                Text("Worth studying before your next round:")
                    .atlasText(.caption).foregroundStyle(Color.canopy600)
                FlowLayout(spacing: Space.s) {
                    ForEach(app.match.prepTopics.prefix(4), id: \.self) { t in
                        Text(t).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.canopy900)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.canopyMist))
                    }
                }
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopyPaperDeep))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Derived data

    private struct Signal { let action: String; let present: Bool; let weight: Int }

    private var signals: [Signal] {
        let p = profile.profile, pref = p.preferences
        return [
            Signal(action: "Add your CV", present: !p.experiences.isEmpty, weight: 30),
            Signal(action: "Connect LinkedIn", present: p.linkedIn != nil, weight: 15),
            Signal(action: "Connect GitHub", present: p.github != nil, weight: 10),
            Signal(action: "Add interests", present: !pref.hobbies.isEmpty, weight: 10),
            Signal(action: "Set work style", present: !pref.arrangements.isEmpty, weight: 10),
            Signal(action: "Set role type", present: !pref.workTypes.isEmpty, weight: 5),
            Signal(action: "Set availability", present: pref.startAvailability != nil, weight: 10),
            Signal(action: "Set relocation", present: pref.openToAnywhere || !pref.relocationCountries.isEmpty, weight: 10),
        ]
    }

    private var confidence: Int { signals.filter(\.present).reduce(0) { $0 + $1.weight } }

    private var topMatch: Int { jobs.matches.map(\.match).max() ?? 0 }
    private var avgMatch: Int {
        jobs.matches.isEmpty ? 0 : jobs.matches.map(\.match).reduce(0, +) / jobs.matches.count
    }
    private var interviewingCount: Int {
        jobs.applications.filter { $0.stage.rawValue >= PipelineStage.interviewing.rawValue }.count
    }
    private var furthestApplication: Application? {
        jobs.applications.max { $0.stage.rawValue < $1.stage.rawValue }
    }

    private func countWord(_ n: Int) -> String {
        switch n {
        case 1: "One detail"
        case 2: "Two details"
        case 3: "Three details"
        default: "\(n) details"
        }
    }
}

/// A circular confidence gauge — amber arc on a hairline track, % in the center.
struct ConfidenceRing: View {
    let progress: Double
    var size: CGFloat = 76

    var body: some View {
        ZStack {
            Circle().stroke(Color.canopyPaperLine, lineWidth: 7)
            Circle().trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.sun, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: size * 0.26, weight: .bold)).foregroundStyle(Color.canopy900)
        }
        .frame(width: size, height: size)
    }
}
