import SwiftUI

/// Correction sheets for the confirm screen — plain fields, add and delete
/// rows. Nothing fancy; this is correction, not authoring. Entirely empty rows
/// are dropped on Done so blanks never persist as data.

struct ExperienceEditSheet: View {
    @Binding var experiences: [Experience]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach($experiences) { $e in
                    Section {
                        TextField("Role", text: $e.role)
                        TextField("Company", text: $e.company)
                        TextField("Start (e.g. 2021)", text: $e.startDate.orEmpty)
                        TextField("End (blank if current)", text: $e.endDate.orEmpty)
                        TextField("Description", text: $e.description.orEmpty, axis: .vertical)
                    }
                }
                .onDelete { experiences.remove(atOffsets: $0) }
                Button {
                    experiences.append(Experience(role: "", company: ""))
                } label: { Label("Add role", systemImage: "plus") }
            }
            .navigationTitle("Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneButton { experiences.removeAll { $0.role.isEmpty && $0.company.isEmpty } } }
        }
    }

    private func doneButton(cleanup: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") { cleanup(); dismiss() }
        }
    }
}

struct EducationEditSheet: View {
    @Binding var education: [Education]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach($education) { $e in
                    Section {
                        TextField("Institution", text: $e.institution)
                        TextField("Degree", text: $e.degree.orEmpty)
                        TextField("Field", text: $e.field.orEmpty)
                        TextField("Start year", text: $e.startYear.orEmpty)
                        TextField("End year", text: $e.endYear.orEmpty)
                    }
                }
                .onDelete { education.remove(atOffsets: $0) }
                Button {
                    education.append(Education(institution: ""))
                } label: { Label("Add education", systemImage: "plus") }
            }
            .navigationTitle("Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        education.removeAll { $0.institution.isEmpty }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SkillsEditSheet: View {
    @Binding var skills: [Skill]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach($skills) { $s in
                    TextField("Skill", text: $s.name)
                }
                .onDelete { skills.remove(atOffsets: $0) }
                Button {
                    skills.append(Skill(name: "", source: .manual))
                } label: { Label("Add skill", systemImage: "plus") }
            }
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        skills.removeAll { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LanguagesEditSheet: View {
    @Binding var languages: [Language]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach($languages) { $l in
                    Section {
                        TextField("Language", text: $l.name)
                        TextField("Level (optional)", text: $l.level.orEmpty)
                    }
                }
                .onDelete { languages.remove(atOffsets: $0) }
                Button {
                    languages.append(Language(name: ""))
                } label: { Label("Add language", systemImage: "plus") }
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        languages.removeAll { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                        dismiss()
                    }
                }
            }
        }
    }
}
