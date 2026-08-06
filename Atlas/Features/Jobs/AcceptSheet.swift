import SwiftUI

/// Shown after accepting a match: an entirely optional note to the company.
/// Sending a line is encouraged ("boost your chances") but never required —
/// the accept is already done; this just adds a personal touch.
struct AcceptSheet: View {
    let match: JobMatch
    var onSend: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    private var trimmed: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                Text("You're in for \(match.role).")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Add a note to \(match.company)? It's optional — but a line on why you're a fit can boost your chances.")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy600)
                    .fixedSize(horizontal: false, vertical: true)
            }

            noteEditor

            VStack(spacing: Space.s) {
                AtlasButton(trimmed.isEmpty ? "Done" : "Send note to \(match.company)") {
                    if !trimmed.isEmpty { onSend(trimmed) }
                    dismiss()
                }
                if !trimmed.isEmpty {
                    Button("Skip the note") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.canopy600)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
            }
        }
        .padding(Space.screen)
        .padding(.top, Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.sheet)
        .presentationBackground(Color.canopyPaper)
    }

    private var noteEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Color.canopyPaperLine, lineWidth: 1)
                )
            if note.isEmpty {
                Text("Hi \(match.company) team — I'm drawn to \(match.role) because…")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy400)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, 16)
            }
            TextEditor(text: $note)
                .font(.system(size: 15))
                .foregroundStyle(Color.canopy900)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Space.m)
                .padding(.vertical, 10)
        }
        .frame(height: 132)
    }
}

#Preview {
    Color.canopyPaper
        .sheet(isPresented: .constant(true)) {
            AcceptSheet(match: JobMatch.samples[0], onSend: { _ in })
        }
}
