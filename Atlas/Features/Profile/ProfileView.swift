import SwiftUI
import os

/// The user's profile — everything Atlas extracted from GitHub, LinkedIn and the
/// CV, laid out as a rich, scannable page: a contribution graph, activity stats,
/// pinnable projects, and the usual experience/education/skills. Shares the warm
/// sky + ivory surface so it blends with the rest of the app.
struct ProfileView: View {
    /// Present a back button only when pushed/presented (nil in tab mode).
    var onClose: (() -> Void)? = nil
    /// Show a sign-out action at the bottom (used in tab mode).
    var onSignOut: (() -> Void)? = nil

    @Environment(ProfileStore.self) private var store
    private var p: UserProfile { store.profile }

    @State private var askingForUsername = false
    @State private var username = ""
    @State private var importingLinkedIn = false
    @State private var busy: BrandMark?
    @State private var connectError: String?

    private let log = Logger(subsystem: "canopy.ai", category: "profile")

    var body: some View {
        VStack(spacing: 0) {
            if onClose != nil { navBar }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.block) {
                    header
                    if !p.desiredRoles.isEmpty { rolesSection }

                    // Connected highlights ride high and blend into one profile:
                    // name → GitHub chart → LinkedIn → experience/education → work.
                    if let gh = p.github { githubCard(gh) }
                    if let li = p.linkedIn { linkedInCard(li) }

                    if !p.experiences.isEmpty { experienceSection }
                    if !p.education.isEmpty { educationSection }
                    if let gh = p.github {
                        if !gh.pinnedProjects.isEmpty { pinnedSection(gh) }
                        if !gh.projects.isEmpty { reposSection(gh) }
                    }
                    if !p.skills.isEmpty { skillsSection }
                    if !p.languages.isEmpty { languagesSection }
                    preferencesSection
                    if let url = p.portfolioURL { portfolioCard(url) }

                    // Connect prompts appear only while a source is missing.
                    if p.linkedIn == nil { connectCard(.linkedIn) }
                    if p.github == nil { connectCard(.github) }

                    if let onSignOut {
                        Button(action: onSignOut) {
                            Text("Sign out")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.canopy600)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .padding(.top, Space.s)
                    }
                }
                .padding(.horizontal, Space.screen)
                .padding(.top, onClose == nil ? Space.block : Space.s)
                .padding(.bottom, Space.block)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Your GitHub username", isPresented: $askingForUsername) {
            TextField("octocat", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Import") { Task { await importGitHub() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We read your public profile — repos, followers, and the languages you ship in.")
        }
        .alert("Couldn't import", isPresented: .constant(connectError != nil)) {
            Button("OK") { connectError = nil }
        } message: {
            Text(connectError ?? "")
        }
        .fileImporter(isPresented: $importingLinkedIn,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: false) { result in
            Task { await importLinkedIn(result) }
        }
    }

    // MARK: Real imports

    private func importGitHub() async {
        let handle = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !handle.isEmpty else { return }
        busy = .github
        defer { busy = nil }
        do {
            let (data, skills) = try await BackendClient.importGitHub(username: handle)
            withAnimation(.easeInOut(duration: 0.3)) { store.connectGitHub(data, skills: skills) }
        } catch {
            log.error("GitHub import failed: \(error.localizedDescription, privacy: .public)")
            connectError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// LinkedIn has no API for experience, so the import is the profile PDF the
    /// person exports (Profile → Resources → Save to PDF) run through parse-cv.
    private func importLinkedIn(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), !data.isEmpty else {
            connectError = "That file couldn't be read."
            return
        }
        busy = .linkedIn
        defer { busy = nil }
        do {
            let cv = PickedCV(filename: url.lastPathComponent, byteSize: data.count, data: data)
            let parsed = try await BackendClient.parseCV(.file(cv))
            withAnimation(.easeInOut(duration: 0.3)) { store.applyLinkedIn(parsed) }
        } catch {
            log.error("LinkedIn import failed: \(error.localizedDescription, privacy: .public)")
            connectError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: Nav + header

    private var navBar: some View {
        HStack {
            Button(action: { onClose?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.canopy900)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .accessibilityLabel("Back")
            Spacer()
        }
        .padding(.horizontal, Space.m)
        .frame(height: 44)
    }

    // Dark hero card — the top of the profile, echoing the dark job card.
    private var header: some View {
        HStack(spacing: Space.l) {
            Circle()
                .fill(Color.canopyPaper.opacity(0.14))
                .frame(width: 62, height: 62)
                .overlay(
                    Text(initials(p.fullName))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.canopyPaper)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(p.fullName ?? "You")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color.canopyPaper)
                if let headline = p.headline {
                    Text(headline).atlasText(.body).foregroundStyle(Color.canopy200)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: Space.m) {
                    if let loc = p.location { metaLabel("mappin.and.ellipse", loc, color: Color.canopy200) }
                    if let gh = p.github { metaLabel("chevron.left.forwardslash.chevron.right", "@\(gh.username)", color: Color.canopy200) }
                }
                .padding(.top, 1)
            }
            Spacer(minLength: 0)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.canopy900))
    }

    // MARK: LinkedIn

    private func linkedInCard(_ li: LinkedInData) -> some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.l) {
                connectedHeader("LINKEDIN") { store.disconnectLinkedIn() }
                HStack(spacing: 0) {
                    stat("\(li.roles)", "Roles imported")
                    statDivider
                    stat("\(li.skills)", "Skills imported")
                    statDivider
                    stat(li.importedAt.formatted(.dateTime.month().day()), "Imported")
                }
                Text("From the profile PDF you exported. LinkedIn offers no API for connections or activity, so nothing here is estimated.")
                    .atlasText(.caption).foregroundStyle(Color.canopy400)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: GitHub

    private func githubCard(_ gh: GitHubData) -> some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.m) {
                connectedHeader("GITHUB") { store.disconnectGitHub() }
                // The heatmap is only shown when we have a real contribution
                // count (GitHub's GraphQL API, which needs a token). Drawing a
                // generated one next to real numbers would be inventing data.
                if gh.contributionsLastYear > 0 {
                    ContributionGraph(seed: 7)
                    Text("\(gh.contributionsLastYear.formatted()) contributions in the last year")
                        .atlasText(.caption).foregroundStyle(Color.canopy400)
                } else {
                    Text("@\(gh.username) · contribution history needs a GITHUB_TOKEN on the backend")
                        .atlasText(.caption).foregroundStyle(Color.canopy400)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Rectangle().fill(Color.canopyPaperLine).frame(height: 1).padding(.vertical, Space.xs)
                HStack(spacing: 0) {
                    stat(abbrev(gh.repoCount), "Repos")
                    statDivider
                    stat(abbrev(gh.totalStars), "Stars")
                    statDivider
                    stat(abbrev(gh.followers), "Followers")
                }
            }
        }
    }

    private func pinnedSection(_ gh: GitHubData) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Eyebrow("PINNED")
            ForEach(gh.pinnedProjects) { project in
                pinnedCard(project)
            }
        }
    }

    private func reposSection(_ gh: GitHubData) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack {
                Eyebrow("REPOSITORIES")
                Spacer()
                Text("\(gh.pinnedProjects.count)/3 pinned")
                    .atlasText(.meta).foregroundStyle(Color.canopy400)
            }
            AtlasCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(gh.projects.enumerated()), id: \.element.id) { i, project in
                        repoRow(project, canPin: gh.pinnedProjects.count < 3)
                        if i < gh.projects.count - 1 {
                            Rectangle().fill(Color.canopyPaperLine).frame(height: 1)
                                .padding(.leading, Space.l)
                        }
                    }
                }
            }
        }
    }

    private func pinnedCard(_ project: GitHubProject) -> some View {
        AtlasCard(padding: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack {
                    repoGlyph
                    Text(project.name).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                    Spacer()
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.canopy600)
                }
                if let d = project.description {
                    Text(d).atlasText(.caption).foregroundStyle(Color.canopy600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                projectMeta(project)
            }
        }
    }

    private func repoRow(_ project: GitHubProject, canPin: Bool) -> some View {
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: 5) {
                Text(project.name).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                if let d = project.description {
                    Text(d).atlasText(.caption).foregroundStyle(Color.canopy400).lineLimit(1)
                }
                projectMeta(project)
            }
            Spacer(minLength: Space.s)
            Button {
                store.togglePin(project.id)
            } label: {
                Image(systemName: project.pinned ? "pin.fill" : "pin")
                    .font(.system(size: 15))
                    .foregroundStyle(project.pinned ? Color.canopy600 : Color.canopy400)
                    .frame(width: 44, height: 44)
            }
            .opacity(project.pinned || canPin ? 1 : 0.35)
            .disabled(!project.pinned && !canPin)
            .accessibilityLabel(project.pinned ? "Unpin \(project.name)" : "Pin \(project.name)")
        }
        .padding(.leading, Space.l)
        .padding(.trailing, Space.xs)
        .padding(.vertical, Space.m)
    }

    private func projectMeta(_ project: GitHubProject) -> some View {
        HStack(spacing: Space.l) {
            if let lang = project.language {
                HStack(spacing: 5) {
                    Circle().fill(langColor(lang)).frame(width: 9, height: 9)
                    Text(lang).atlasText(.caption).foregroundStyle(Color.canopy600)
                }
            }
            metaLabel("star", "\(project.stars)")
            metaLabel("tuningfork", "\(project.forks)")
        }
    }

    // MARK: CV sections

    private var experienceSection: some View {
        sectionCard("EXPERIENCE") {
            ForEach(Array(p.experiences.enumerated()), id: \.element.id) { i, e in
                if i > 0 { rowDivider }
                HStack(spacing: Space.m) {
                    monogram(e.company)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.role).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        Text("\(e.company) · \(dateRange(e.startDate, e.endDate))")
                            .atlasText(.caption).foregroundStyle(Color.canopy600)
                    }
                    Spacer()
                }
            }
        }
    }

    private var educationSection: some View {
        sectionCard("EDUCATION") {
            ForEach(Array(p.education.enumerated()), id: \.element.id) { i, e in
                if i > 0 { rowDivider }
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.institution).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                    Text([e.degree, e.field].compactMap { $0 }.joined(separator: ", ")
                         + years(e.startYear, e.endYear))
                        .atlasText(.caption).foregroundStyle(Color.canopy600)
                }
            }
        }
    }

    private var skillsSection: some View {
        sectionCard("SKILLS") {
            FlowLayout {
                ForEach(p.skills) { ChipView(text: $0.name) }
            }
        }
    }

    private var languagesSection: some View {
        sectionCard("LANGUAGES") {
            FlowLayout {
                ForEach(p.languages) { lang in
                    ChipView(text: lang.level.map { "\(lang.name) · \($0)" } ?? lang.name)
                }
            }
        }
    }

    private var preferencesSection: some View {
        sectionCard("WHAT YOU'RE LOOKING FOR") {
            PreferencesSummary(prefs: p.preferences)
        }
    }

    private var rolesSection: some View {
        sectionCard("LOOKING FOR") {
            FlowLayout {
                ForEach(p.desiredRoles, id: \.self) { role in
                    Text(role)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.canopy600)
                        .padding(.vertical, 8).padding(.horizontal, 13)
                        .background(Capsule().fill(Color.canopyMist))
                }
            }
        }
    }

    @ViewBuilder
    private func portfolioCard(_ url: String) -> some View {
        // An unparseable link renders as plain text rather than a dead Link (and
        // never a force-unwrapped placeholder URL).
        if let destination = URL(string: url.hasPrefix("http") ? url : "https://\(url)") {
            sectionCard("PORTFOLIO") {
                Link(destination: destination) { portfolioRow(url, isLink: true) }
            }
        } else {
            sectionCard("PORTFOLIO") { portfolioRow(url, isLink: false) }
        }
    }

    private func portfolioRow(_ url: String, isLink: Bool) -> some View {
        HStack(spacing: Space.s) {
            Image(systemName: "link").font(.system(size: 13))
            Text(url).atlasText(.body).lineLimit(1).truncationMode(.middle)
            Spacer(minLength: 0)
            if isLink {
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(Color.canopy600)
    }

    // MARK: Connectors (optional, reversible)

    private func connectedHeader(_ title: String, disconnect: @escaping () -> Void) -> some View {
        HStack {
            Eyebrow(title)
            Spacer()
            Button("Disconnect") { withAnimation(.easeInOut(duration: 0.25)) { disconnect() } }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.canopy400)
        }
    }

    private func connectCard(_ mark: BrandMark) -> some View {
        let isLinkedIn = mark == .linkedIn
        return Button {
            if isLinkedIn { importingLinkedIn = true } else { askingForUsername = true }
        } label: {
            AtlasCard(padding: Space.l) {
                HStack(spacing: Space.m) {
                    BrandMarkView(mark: mark, size: 34, monoColor: Color.canopy900)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLinkedIn ? "Connect LinkedIn" : "Connect GitHub")
                            .atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        Text(isLinkedIn ? "Export your profile as PDF — we read it."
                                        : "Import your public repos and languages.")
                            .atlasText(.caption).foregroundStyle(Color.canopy600)
                    }
                    Spacer(minLength: Space.s)
                    if busy == mark {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(isLinkedIn ? "Import" : "Connect")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.canopy600)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Bits

    private func sectionCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.m) {
                Eyebrow(title)
                content()
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .semibold)).foregroundStyle(Color.canopy900)
            Text(label).atlasText(.meta).foregroundStyle(Color.canopy400)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.canopyPaperLine).frame(width: 1, height: 30)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color.canopyPaperLine).frame(height: 1).padding(.vertical, Space.xs)
    }

    private func metaLabel(_ symbol: String, _ text: String, color: Color = Color.canopy400) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 11, weight: .regular))
            Text(text).atlasText(.caption)
        }
        .foregroundStyle(color)
    }

    private var repoGlyph: some View {
        Image(systemName: "chevron.left.forwardslash.chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.canopy600)
    }

    private func monogram(_ name: String) -> some View {
        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
            .fill(Color.canopyMist)
            .frame(width: 38, height: 38)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.canopy600)
            )
    }

    private func initials(_ name: String?) -> String {
        guard let name, !name.isEmpty else { return "You".prefix(1).uppercased() }
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    private func dateRange(_ start: String?, _ end: String?) -> String {
        let s = start ?? ""
        let e = end ?? "Present"
        return s.isEmpty ? e : "\(s) — \(e)"
    }

    private func years(_ start: String?, _ end: String?) -> String {
        guard start != nil || end != nil else { return "" }
        return " · \(start ?? "") — \(end ?? "")"
    }

    private func abbrev(_ n: Int) -> String {
        guard n >= 1000 else { return "\(n)" }
        let v = Double(n) / 1000
        return String(format: v >= 10 ? "%.0fk" : "%.1fk", v)
    }

    private func langColor(_ lang: String) -> Color {
        switch lang {
        case "Swift": return Color(hex: "F05138")
        case "TypeScript": return Color(hex: "3178C6")
        case "JavaScript": return Color(hex: "E7CF51")
        case "Rust": return Color(hex: "DEA584")
        case "Shell": return Color(hex: "89E051")
        case "Metal": return Color(hex: "8E7BEF")
        case "Python": return Color(hex: "3572A5")
        default: return Color.canopy400
        }
    }
}

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return ProfileView(onClose: {}).environment(store)
}
