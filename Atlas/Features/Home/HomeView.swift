import SwiftUI

/// S06 · Home (stub). What's coming, plus a read-only summary of the profile
/// they just built. One sign-out text button at the bottom.
struct HomeView: View {
    var onSignOut: () -> Void

    @Environment(ProfileStore.self) private var store

    private var profile: UserProfile { store.profile }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.block) {
                    Eyebrow("ATLAS")

                    VStack(alignment: .leading, spacing: Space.l) {
                        Text("Your matches are\nbeing prepared.")
                            .atlasText(.display)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("We're building the matching engine next. You'll get an email the day it's ready.")
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

            Button(action: onSignOut) {
                Text("Sign out")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.blue)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, Space.screen)
            .padding(.bottom, Space.screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
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
    return HomeView(onSignOut: {}).environment(store)
}
