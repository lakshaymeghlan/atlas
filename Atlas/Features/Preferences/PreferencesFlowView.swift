import SwiftUI
import UIKit

/// S04–09 · The preferences wizard. Six paged steps between the CV analysis and
/// the profile review — work style, work type, relocation, priorities (drag to
/// rank), salary, and availability. Each step reuses `OnboardingScaffold` so the
/// progress bar and back nav stay consistent; answers write straight to the
/// profile so a force-quit resumes intact.
struct PreferencesFlowView: View {
    @Environment(ProfileStore.self) private var store
    var onComplete: () -> Void
    var onBackToUpload: () -> Void

    @State private var step: Step = .hobbies
    @State private var customHobby = ""
    @FocusState private var hobbyFocused: Bool
    @State private var countryQuery = ""
    @State private var suggestions: [String] = []
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var countryFocused: Bool
    private enum Step: Int, CaseIterable { case hobbies, arrangement, workType, relocation, priorities, salary, timing }

    /// Each selection step needs at least one answer before Continue unlocks.
    private var isStepValid: Bool {
        switch step {
        case .hobbies: !prefs.hobbies.isEmpty
        case .arrangement: !prefs.arrangements.isEmpty
        case .workType: !prefs.workTypes.isEmpty
        case .relocation: prefs.openToAnywhere || !prefs.relocationCountries.isEmpty
        case .priorities, .salary: true
        case .timing: prefs.startAvailability != nil
        }
    }

    private var prefs: JobPreferences { store.profile.preferences }

    var body: some View {
        Group {
            switch step {
            case .hobbies:
                wizardStep(0, "WHAT YOU LOVE", "What makes life\nfeel like yours?",
                           "Pick up to 5 — the things you'd protect time for.") { hobbiesStep }
            case .arrangement:
                wizardStep(1, "WORK STYLE", "Where do you\nwant to work?",
                           "Pick any that work for you — remote, hybrid, or in office.") { arrangementStep }
            case .workType:
                wizardStep(2, "WORK TYPE", "What kind\nof role?",
                           "Select any that fit.") { workTypeStep }
            case .relocation:
                wizardStep(3, "RELOCATION", "Open to\nrelocating?",
                           "If a company sponsors your visa, where would you go? Pick any.") { relocationStep }
            case .priorities:
                wizardStep(4, "PRIORITIES", "What matters most\nin your next move?",
                           "Drag to rank. Your top three shape your matches.") { prioritiesStep }
            case .salary:
                wizardStep(5, "SALARY", "What salary makes\na move worthwhile?",
                           "This is private. We use it to filter out roles that wouldn't work for you financially.") { salaryStep }
            case .timing:
                wizardStep(6, "AVAILABILITY", "A couple of\npractical details.",
                           "Almost done — when could you start?") { timingStep }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    // MARK: Scaffold + navigation

    @ViewBuilder
    private func wizardStep<C: View>(_ index: Int, _ name: String, _ title: String,
                                     _ subtitle: String, @ViewBuilder content: @escaping () -> C) -> some View {
        OnboardingScaffold(stageIndex: 1 + index, onBack: { back() }) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("\(name) · \(index + 2) OF \(Journey.onboardingSteps)")
                Text(title).atlasText(.display).foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle).atlasText(.body).foregroundStyle(Color.canopy600)
            }
            content()
        } bottom: {
            AtlasButton(index == Step.allCases.count - 1 ? "Review my profile →" : "Continue →",
                        isEnabled: isStepValid) { advance() }
        }
    }

    private func advance() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        if let next = Step(rawValue: step.rawValue + 1) { step = next } else { onComplete() }
    }

    private func back() {
        if let prev = Step(rawValue: step.rawValue - 1) { step = prev } else { onBackToUpload() }
    }

    // MARK: Steps

    private var hobbiesStep: some View {
        let atMax = prefs.hobbies.count >= Hobbies.maxSelectable
        // Custom-added hobbies (not in the preset list) appear as selected chips too.
        let customs = prefs.hobbies.filter { !Hobbies.options.contains($0) }.sorted()
        return VStack(alignment: .leading, spacing: Space.m) {
            FlowLayout(spacing: Space.s) {
                ForEach(Hobbies.options + customs, id: \.self) { h in
                    let on = prefs.hobbies.contains(h)
                    PrefChip(text: h, selected: on) { toggleHobby(h) }
                        .opacity(!on && atMax ? 0.4 : 1)
                }
            }
            addOwnField(atMax: atMax)
        }
    }

    private func addOwnField(atMax: Bool) -> some View {
        HStack(spacing: Space.s) {
            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.canopy400)
            TextField(atMax ? "That's 5 — remove one to add another" : "Add your own", text: $customHobby)
                .font(.system(size: 15)).foregroundStyle(Color.canopy900)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($hobbyFocused)
                .disabled(atMax)
                .onSubmit { addCustomHobby() }
        }
        .padding(.horizontal, Space.l)
        .frame(height: 48)
        .background(Color.canopyPaperDeep)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(hobbyFocused ? Color.canopy600 : Color.canopyPaperLine, lineWidth: 1))
        .opacity(atMax ? 0.5 : 1)
    }

    private func addCustomHobby() {
        let h = customHobby.trimmingCharacters(in: .whitespacesAndNewlines)
        customHobby = ""
        guard !h.isEmpty, prefs.hobbies.count < Hobbies.maxSelectable,
              !prefs.hobbies.contains(where: { $0.caseInsensitiveCompare(h) == .orderedSame }) else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
        store.profile.preferences.hobbies.insert(h)
    }

    private func toggleHobby(_ h: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
        if prefs.hobbies.contains(h) {
            store.profile.preferences.hobbies.remove(h)
        } else if prefs.hobbies.count < Hobbies.maxSelectable {
            store.profile.preferences.hobbies.insert(h)
        }
    }

    private var arrangementStep: some View {
        FlowLayout(spacing: Space.s) {
            ForEach(WorkArrangement.allCases) { a in
                PrefChip(text: a.label, selected: prefs.arrangements.contains(a)) {
                    toggle(a, in: \.arrangements)
                }
            }
        }
    }

    private var workTypeStep: some View {
        FlowLayout(spacing: Space.s) {
            ForEach(WorkType.allCases) { t in
                PrefChip(text: t.label, selected: prefs.workTypes.contains(t)) {
                    toggle(t, in: \.workTypes)
                }
            }
        }
    }

    private var relocationStep: some View {
        // Popular chips plus any country the person searched for and added.
        let customs = prefs.relocationCountries.filter { !Relocation.destinations.contains($0) }.sorted()
        return VStack(alignment: .leading, spacing: Space.m) {
            PrefChip(text: "Open to anywhere", selected: prefs.openToAnywhere) {
                store.profile.preferences.openToAnywhere.toggle()
            }
            countrySearch
            FlowLayout(spacing: Space.s) {
                ForEach(Relocation.destinations + customs, id: \.self) { c in
                    PrefChip(text: c, selected: prefs.relocationCountries.contains(c)) {
                        toggleCountry(c)
                    }
                }
            }
        }
    }

    private var countrySearch: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.s) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(Color.canopy400)
                TextField("Search a country", text: $countryQuery)
                    .font(.system(size: 15)).foregroundStyle(Color.canopy900)
                    .autocorrectionDisabled().submitLabel(.done)
                    .focused($countryFocused)
                    .onSubmit { if let first = suggestions.first { addCountry(first) } }
            }
            .padding(.horizontal, Space.l).frame(height: 48)
            .background(Color.canopyPaperDeep).clipShape(Capsule())
            .overlay(Capsule().strokeBorder(countryFocused ? Color.canopy600 : Color.canopyPaperLine, lineWidth: 1))
            .onChange(of: countryQuery) { _, q in scheduleSearch(q) }

            if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { s in
                        Button { addCountry(s) } label: {
                            HStack {
                                Text(s).font(.system(size: 15)).foregroundStyle(Color.canopy900)
                                Spacer()
                                Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.canopy400)
                            }
                            .padding(.horizontal, Space.l).frame(height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if s != suggestions.last {
                            Divider().overlay(Color.canopyPaperLine).padding(.leading, Space.l)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.canopyPaperDeep))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.canopyPaperLine, lineWidth: 1))
            }
        }
    }

    // Debounced (250ms) prefix-first search over the full country list.
    private func scheduleSearch(_ q: String) {
        searchTask?.cancel()
        let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { suggestions = []; return }
        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
            let ql = query.lowercased()
            let matches = Relocation.allCountries.filter {
                !store.profile.preferences.relocationCountries.contains($0)
                    && $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            let ranked = matches.sorted {
                let ap = $0.lowercased().hasPrefix(ql), bp = $1.lowercased().hasPrefix(ql)
                return ap == bp ? $0 < $1 : ap
            }
            suggestions = Array(ranked.prefix(6))
        }
    }

    private func addCountry(_ c: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
        store.profile.preferences.relocationCountries.insert(c)
        countryQuery = ""
        suggestions = []
        countryFocused = false
    }

    private var prioritiesStep: some View {
        List {
            ForEach(prefs.priorities) { p in
                priorityRow(p)
                    .listRowInsets(EdgeInsets(top: 0, leading: Space.l, bottom: 0, trailing: Space.m))
                    .listRowBackground(rowTint(p))
                    .listRowSeparatorTint(Color.canopyPaperLine)
            }
            .onMove { from, to in
                store.profile.preferences.priorities.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .environment(\.editMode, .constant(.active))
        .frame(height: CGFloat(prefs.priorities.count) * 52)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .strokeBorder(Color.canopyPaperLine, lineWidth: 1))
    }

    private func rowTint(_ p: WorkPriority) -> Color {
        (prefs.priorities.firstIndex(of: p) ?? 0) < 3 ? Color.sun.opacity(0.14) : Color.canopyPaper
    }

    private func priorityRow(_ p: WorkPriority) -> some View {
        let idx = prefs.priorities.firstIndex(of: p) ?? 0
        let top3 = idx < 3
        return HStack(spacing: Space.m) {
            ZStack {
                Circle().fill(top3 ? Color.sun : Color.canopyMist).frame(width: 24, height: 24)
                Text("\(idx + 1)").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(top3 ? Color.canopy900 : Color.canopy600)
            }
            Text(p.label)
                .font(Typeface.body(16, weight: top3 ? .medium : .regular))
                .foregroundStyle(Color.canopy900)
            Spacer()
        }
        .frame(height: 52)
    }

    private var salaryStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(prefs.salaryOpen ? "Open" : "€\(prefs.minSalary.formatted(.number.grouping(.automatic)))")
                    .font(Typeface.display(40)).foregroundStyle(Color.canopy900)
                if !prefs.salaryOpen {
                    Text("/ yr").atlasText(.body).foregroundStyle(Color.canopy400)
                }
            }
            Slider(value: salaryBinding, in: 25_000...150_000, step: 5_000)
                .tint(Color.canopy600)
                .disabled(prefs.salaryOpen)
                .opacity(prefs.salaryOpen ? 0.35 : 1)
            HStack {
                Text("€25k").atlasText(.caption).foregroundStyle(Color.canopy400)
                Spacer()
                Text("€150k").atlasText(.caption).foregroundStyle(Color.canopy400)
            }

            Button {
                store.profile.preferences.salaryOpen.toggle()
            } label: {
                HStack(spacing: Space.m) {
                    Image(systemName: prefs.salaryOpen ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20)).foregroundStyle(prefs.salaryOpen ? Color.canopy600 : Color.canopy400)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I'm open on salary").atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        Text("Show me all strong matches regardless of pay")
                            .atlasText(.caption).foregroundStyle(Color.canopy400)
                    }
                    Spacer()
                }
                .padding(Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.canopyPaperDeep))
            }
            .buttonStyle(.plain)
        }
    }

    private var salaryBinding: Binding<Double> {
        Binding(
            get: { Double(store.profile.preferences.minSalary) },
            set: { store.profile.preferences.minSalary = Int(($0 / 5_000).rounded()) * 5_000 })
    }

    private var timingStep: some View {
        VStack(spacing: Space.s) {
            ForEach(StartAvailability.allCases) { option in
                let selected = prefs.startAvailability == option
                Button {
                    store.profile.preferences.startAvailability = option
                } label: {
                    HStack(spacing: Space.m) {
                        Text(option.label)
                            .font(Typeface.body(16, weight: .medium))
                            .foregroundStyle(selected ? Color.canopyPaper : Color.canopy900)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(selected ? Color.canopyPaper : Color.canopy400)
                    }
                    .padding(Space.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? Color.canopy800 : Color.canopyPaperDeep))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.canopyPaperLine, lineWidth: selected ? 0 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Mutation helpers

    private func toggle<T: Hashable>(_ v: T, in key: WritableKeyPath<JobPreferences, Set<T>>) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
        if store.profile.preferences[keyPath: key].contains(v) {
            store.profile.preferences[keyPath: key].remove(v)
        } else {
            store.profile.preferences[keyPath: key].insert(v)
        }
    }

    private func toggleCountry(_ c: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
        if store.profile.preferences.relocationCountries.contains(c) {
            store.profile.preferences.relocationCountries.remove(c)
        } else {
            store.profile.preferences.relocationCountries.insert(c)
        }
    }
}

/// Capsule multi-select chip — mist when off, canopy fill + check when on.
private struct PrefChip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if selected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
                Text(text).font(.system(size: 14, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? Color.canopyPaper : Color.canopy900)
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(Capsule().fill(selected ? Color.canopy600 : Color.canopyMist))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
