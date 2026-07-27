import SwiftUI
import UniformTypeIdentifiers
import os

/// S03 · Upload CV. Pick a PDF/DOCX from Files, validate inline, then continue.
struct UploadCVView: View {
    var onContinue: (PickedCV) -> Void
    var onBack: () -> Void

    @State private var picked: PickedCV?
    @State private var validationError: CVValidation.Failure?
    @State private var importing = false

    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "upload")

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        return types
    }()

    var body: some View {
        OnboardingScaffold(stageIndex: 1, onBack: onBack) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("UPLOAD CV · 2 OF 3")
                Text("Let's start\nwith your CV.")
                    .atlasText(.display)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Atlas reads it and builds your profile. No forms to fill.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
            }

            VStack(alignment: .leading, spacing: Space.m) {
                if let picked {
                    fileRow(picked)
                } else {
                    dropZone
                }
                if let validationError {
                    Text(validationError.message)
                        .atlasText(.caption)
                        .foregroundStyle(Palette.error)
                }
            }

            orDivider

            VStack(alignment: .leading, spacing: Space.s) {
                AtlasButton(title: "Import from LinkedIn", kind: .secondary, isEnabled: false,
                            leading: { ProviderMark(.linkedIn) }) {}
                Text("LinkedIn only shares your name and email. Your CV is the real story.")
                    .atlasText(.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
        } bottom: {
            AtlasButton("Continue →", isEnabled: picked != nil) {
                if let picked { onContinue(picked) }
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: Self.allowedTypes,
                      allowsMultipleSelection: false,
                      onCompletion: handleImport)
    }

    // MARK: Drop zone / file row

    private var dropZone: some View {
        Button { importing = true } label: {
            VStack(spacing: Space.m) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Palette.chip)
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "arrow.up.doc")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Palette.inkSecondary))
                Text("Drop your PDF here").atlasText(.bodyStrong).foregroundStyle(Palette.ink)
                Text("or tap to browse files").atlasText(.caption).foregroundStyle(Palette.inkTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Upload your CV. PDF or DOCX.")
    }

    private func fileRow(_ cv: PickedCV) -> some View {
        AtlasCard(padding: Space.l) {
            HStack(spacing: Space.m) {
                Image(systemName: "doc.text")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Palette.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cv.filename).atlasText(.bodyStrong).foregroundStyle(Palette.ink)
                        .lineLimit(1).truncationMode(.middle)
                    Text(byteCount(cv.byteSize)).atlasText(.caption).foregroundStyle(Palette.inkTertiary)
                }
                Spacer()
                Button("Replace") { importing = true }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.blue)
            }
        }
    }

    private var orDivider: some View {
        HStack(spacing: Space.m) {
            Rectangle().fill(Palette.border).frame(height: 1)
            Text("or").atlasText(.caption).foregroundStyle(Palette.inkTertiary)
            Rectangle().fill(Palette.border).frame(height: 1)
        }
    }

    // MARK: Import handling

    private func handleImport(_ result: Result<[URL], Error>) {
        validationError = nil
        guard case .success(let urls) = result, let url = urls.first else {
            if case .failure(let error) = result { log.error("Import failed: \(error.localizedDescription)") }
            return
        }

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            validationError = .empty
            return
        }
        let filename = url.lastPathComponent
        if let failure = CVValidation.validate(filename: filename, byteSize: data.count) {
            validationError = failure
            picked = nil
            return
        }
        picked = PickedCV(filename: filename, byteSize: data.count, data: data)
        log.info("Picked \(filename, privacy: .public) (\(data.count) bytes)")
    }

    private func byteCount(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

#Preview {
    UploadCVView(onContinue: { _ in }, onBack: {})
}
