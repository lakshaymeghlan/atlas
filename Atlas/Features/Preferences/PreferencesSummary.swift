import SwiftUI

/// A clean, structured read-out of everything picked in the preferences wizard.
/// Reused on the profile review and the Profile tab so both stay in sync.
struct PreferencesSummary: View {
    let prefs: JobPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            if !prefs.hobbies.isEmpty {
                chips("What you love", prefs.hobbies.sorted())
            }
            if !prefs.arrangements.isEmpty {
                chips("Work style", WorkArrangement.allCases.filter { prefs.arrangements.contains($0) }.map(\.label))
            }
            if !prefs.workTypes.isEmpty {
                chips("Role type", WorkType.allCases.filter { prefs.workTypes.contains($0) }.map(\.label))
            }
            relocationBlock
            prioritiesBlock
            valueRow("Salary", salaryText)
            if let start = prefs.startAvailability {
                valueRow("Can start", start.label)
            }
        }
    }

    // MARK: Blocks

    private var relocationBlock: some View {
        Group {
            if prefs.openToAnywhere || !prefs.relocationCountries.isEmpty {
                let items = (prefs.openToAnywhere ? ["Anywhere"] : []) + prefs.relocationCountries.sorted()
                chips("Open to relocating", items)
            }
        }
    }

    private var prioritiesBlock: some View {
        let top = Array(prefs.priorities.prefix(3))
        return VStack(alignment: .leading, spacing: Space.s) {
            label("Top priorities")
            HStack(spacing: Space.s) {
                ForEach(Array(top.enumerated()), id: \.offset) { i, p in
                    HStack(spacing: 6) {
                        ZStack {
                            Circle().fill(Color.sun).frame(width: 18, height: 18)
                            Text("\(i + 1)").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.canopy900)
                        }
                        Text(p.label).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.canopy900)
                    }
                    .padding(.trailing, 8).padding(.leading, 4).padding(.vertical, 5)
                    .background(Capsule().fill(Color.sun.opacity(0.16)))
                }
            }
        }
    }

    // MARK: Pieces

    private func chips(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            label(title)
            FlowLayout(spacing: Space.s) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.canopy900)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(Color.canopyMist))
                }
            }
        }
    }

    private func valueRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            label(title)
            Text(value).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .tracking(1.4).foregroundStyle(Color.canopy400)
    }

    private var salaryText: String {
        prefs.salaryOpen ? "Open to any" : "€\(prefs.minSalary.formatted(.number.grouping(.automatic)))+ / yr"
    }
}
