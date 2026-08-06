import SwiftUI

/// S04 · What are you looking for? Pick from common roles across fields, or type
/// your own. Multi-select. Drives matching later.
struct RolePreferencesView: View {
    var onContinue: ([String]) -> Void

    @State private var options: [String] = [
        "Software Engineer", "iOS Engineer", "Product Designer", "Product Manager",
        "Data Scientist", "Frontend Engineer", "Engineering Manager", "UX Researcher",
        "Marketing Manager", "Consultant", "Lawyer", "Financial Analyst", "Content Writer",
    ]
    @State private var selected: Set<String> = []
    @State private var custom: String = ""
    @FocusState private var customFocused: Bool

    private var trimmed: String { custom.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var chosen: [String] { options.filter { selected.contains($0) } }

    var body: some View {
        OnboardingScaffold(stageIndex: 1) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("ROLES · 2 OF 3")
                Text("What are you\nlooking for?")
                    .atlasText(.display)
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Pick a few roles, or type your own. Canopy matches you to these — you can change them anytime.")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy600)
            }

            FlowLayout(spacing: Space.s) {
                ForEach(options, id: \.self) { role in
                    SelectableChip(text: role, selected: selected.contains(role)) {
                        toggle(role)
                    }
                }
            }

            addField
        } bottom: {
            AtlasButton("Continue →", isEnabled: !selected.isEmpty) {
                onContinue(chosen)
            }
        }
    }

    private var addField: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.canopy400)
            TextField("Add a role", text: $custom)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($customFocused)
                .font(.system(size: 16))
                .foregroundStyle(Color.canopy900)
                .onSubmit(addCustom)
            if !trimmed.isEmpty {
                Button("Add", action: addCustom)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.canopy600)
            }
        }
        .padding(.horizontal, Space.l)
        .frame(height: 54)
        .background(Color.canopyPaperDeep)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                .strokeBorder(customFocused ? Color.canopy600 : Color.canopyPaperLine, lineWidth: 1)
        )
    }

    private func toggle(_ role: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selected.contains(role) { selected.remove(role) } else { selected.insert(role) }
        }
    }

    private func addCustom() {
        let role = trimmed
        guard !role.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if !options.contains(where: { $0.caseInsensitiveCompare(role) == .orderedSame }) {
                options.insert(role, at: 0)
            }
            selected.insert(role)
        }
        custom = ""
    }
}

/// A toggleable pill — blue when selected, quiet chip when not.
private struct SelectableChip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                }
                Text(text).font(.system(size: 14, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? .white : Color.canopy900)
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(selected ? Color.canopy600 : Color.canopyMist)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

#Preview {
    RolePreferencesView(onContinue: { _ in })
}
