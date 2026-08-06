import SwiftUI

/// S05 · Confirm profile. Section cards over the parsed data; tap any card to
/// edit. Low-confidence fields get a blue dot and sort to the top. Nothing is
/// invented — missing fields read "Add …", never a guess.
struct ConfirmProfileView: View {
    var onDone: () -> Void

    @Environment(ProfileStore.self) private var store
    @State private var editing: Section?

    enum Section: String, Identifiable {
        case experience, education, skills, languages
        var id: String { rawValue }
    }

    private let skillLimit = 8

    var body: some View {
        @Bindable var store = store

        return OnboardingScaffold(stageIndex: 2) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("CONFIRM PROFILE · 3 OF 3")
                Text("Here's what\nwe found.")
                    .atlasText(.display)
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap any card to edit.")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy600)
            }

            experienceCard
            educationCard
            skillsCard
            languagesCard
        } bottom: {
            AtlasButton("Looks good", action: onDone)
        }
        .sheet(item: $editing) { section in
            editSheet(for: section, store: store)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(Radius.sheet)
        }
    }

    // MARK: Cards

    private var experienceCard: some View {
        let items = sortedByConfidence(store.profile.experiences, low: \.isLowConfidence)
        return card("EXPERIENCE", .experience, isEmpty: items.isEmpty, addLabel: "Add experience") {
            VStack(alignment: .leading, spacing: Space.l) {
                ForEach(items) { exp in experienceRow(exp) }
            }
        }
    }

    private func experienceRow(_ e: Experience) -> some View {
        HStack(spacing: Space.m) {
            monogram(e.company)
            VStack(alignment: .leading, spacing: 2) {
                labeled(e.role, low: e.isLowConfidence, style: .bodyStrong)
                let subtitle = [e.company, dateRange(e.startDate, e.endDate, current: true)]
                    .filter { !$0.isEmpty }.joined(separator: " · ")
                Text(subtitle).atlasText(.caption).foregroundStyle(Color.canopy400)
            }
            Spacer(minLength: 0)
        }
    }

    private var educationCard: some View {
        let items = sortedByConfidence(store.profile.education, low: \.isLowConfidence)
        return card("EDUCATION", .education, isEmpty: items.isEmpty, addLabel: "Add education") {
            VStack(alignment: .leading, spacing: Space.l) {
                ForEach(items) { edu in educationRow(edu) }
            }
        }
    }

    private func educationRow(_ e: Education) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            labeled(e.institution, low: e.isLowConfidence, style: .bodyStrong)
            let degree = [e.degree, e.field].compactMap { $0 }.joined(separator: " ")
            let years = dateRange(e.startYear, e.endYear, current: false)
            let subtitle = [degree, years].filter { !$0.isEmpty }.joined(separator: " · ")
            Text(subtitle.isEmpty ? "Add details" : subtitle)
                .atlasText(.caption)
                .foregroundStyle(Color.canopy400)
        }
    }

    private var skillsCard: some View {
        let items = sortedByConfidence(store.profile.skills, low: \.isLowConfidence)
        let shown = Array(items.prefix(skillLimit))
        let overflow = items.count - shown.count
        return card("SKILLS", .skills, isEmpty: items.isEmpty, addLabel: "Add skills") {
            FlowLayout {
                ForEach(shown) { s in ChipView(text: s.name, lowConfidence: s.isLowConfidence) }
                if overflow > 0 { ChipView(text: "+\(overflow) more", selected: true) }
            }
        }
    }

    private var languagesCard: some View {
        let items = store.profile.languages
        return card("LANGUAGES", .languages, isEmpty: items.isEmpty, addLabel: "Add languages") {
            FlowLayout {
                ForEach(items) { l in
                    ChipView(text: l.level.map { "\(l.name) · \($0)" } ?? l.name)
                }
            }
        }
    }

    // MARK: Building blocks

    private func card<Content: View>(
        _ title: String, _ section: Section, isEmpty: Bool, addLabel: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button { editing = section } label: {
            AtlasCard {
                VStack(alignment: .leading, spacing: Space.m) {
                    HStack {
                        Eyebrow(title)
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.canopy400)
                    }
                    if isEmpty {
                        Text(addLabel).atlasText(.body).foregroundStyle(Color.canopy400)
                    } else {
                        content()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit \(title.lowercased())")
    }

    private func labeled(_ text: String, low: Bool, style: TextRole) -> some View {
        HStack(spacing: Space.xs) {
            if low { Circle().fill(Color.canopy600).frame(width: 6, height: 6) }
            Text(text).atlasText(style).foregroundStyle(Color.canopy900)
        }
    }

    private func monogram(_ company: String) -> some View {
        let letter = company.first.map { String($0).uppercased() } ?? "—"
        return RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
            .fill(Color.canopyMist)
            .frame(width: 40, height: 40)
            .overlay(Text(letter).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.canopy600))
            .accessibilityHidden(true)
    }

    private func dateRange(_ start: String?, _ end: String?, current: Bool) -> String {
        switch (start, end) {
        case let (s?, e?): return "\(s) — \(e)"
        case let (s?, nil): return current ? "\(s) — Present" : s
        case let (nil, e?): return e
        case (nil, nil): return ""
        }
    }

    /// Low-confidence items first (stable within each group).
    private func sortedByConfidence<T>(_ items: [T], low: (T) -> Bool) -> [T] {
        items.filter(low) + items.filter { !low($0) }
    }

    @ViewBuilder
    private func editSheet(for section: Section, store: ProfileStore) -> some View {
        @Bindable var store = store
        switch section {
        case .experience: ExperienceEditSheet(experiences: $store.profile.experiences)
        case .education:  EducationEditSheet(education: $store.profile.education)
        case .skills:     SkillsEditSheet(skills: $store.profile.skills)
        case .languages:  LanguagesEditSheet(languages: $store.profile.languages)
        }
    }
}

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return ConfirmProfileView(onDone: {})
        .environment(store)
}
