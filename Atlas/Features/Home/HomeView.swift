import SwiftUI

/// Jobs tab. What's coming (the matching engine) plus a quick summary of the
/// profile Atlas just built. Sign-out lives on the Profile tab now.
struct HomeView: View {
    @Environment(ProfileStore.self) private var store

    private var profile: UserProfile { store.profile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.block) {
                Eyebrow("JOBS")

                VStack(alignment: .leading, spacing: Space.l) {
                    Text("Your matches are\nbeing prepared.")
                        .atlasText(.display)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("We're building the matching engine next. You'll get a nudge the day roles that fit you land here.")
                        .atlasText(.body)
                        .foregroundStyle(Palette.inkSecondary)
                }

                summaryCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.screen)
            .padding(.top, Space.block)
            .padding(.bottom, Space.block)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .atlasSky(height: 300, intensity: 0.8, maxClouds: 3)
    }

    private var summaryCard: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("YOUR PROFILE")

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.fullName ?? "You")
                        .atlasText(.title).foregroundStyle(Palette.ink)
                    if let headline = profile.headline {
                        Text(headline).atlasText(.body).foregroundStyle(Palette.inkSecondary)
                    }
                    if let location = profile.location {
                        Text(location).atlasText(.caption).foregroundStyle(Palette.inkTertiary)
                    }
                }

                if let latest = profile.experiences.first {
                    summaryRow("MOST RECENT", "\(latest.role) · \(latest.company)")
                }
                if !profile.skills.isEmpty {
                    VStack(alignment: .leading, spacing: Space.s) {
                        Eyebrow("SKILLS", color: Palette.inkTertiary)
                        FlowLayout {
                            ForEach(Array(profile.skills.prefix(6))) { skill in
                                ChipView(text: skill.name)
                            }
                        }
                    }
                }
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Eyebrow(label, color: Palette.inkTertiary)
            Text(value).atlasText(.bodyStrong).foregroundStyle(Palette.ink)
        }
    }
}

#Preview {
    let store = ProfileStore()
    if let result = try? CVParseResult.decode(MockCVParser.sampleJSON) {
        store.apply(result, email: "you@example.com")
    }
    return HomeView().environment(store)
}
