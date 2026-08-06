import SwiftUI
import UniformTypeIdentifiers
import os

/// S03 · Add your CV or a link. Upload a PDF/DOCX, or paste a portfolio / profile
/// URL — Canopy reads either and builds the profile. Works for any field.
struct UploadCVView: View {
    var onContinue: (CVSource) -> Void
    var onBack: (() -> Void)? = nil

    @State private var picked: PickedCV?
    @State private var link: String = ""
    @State private var validationError: CVValidation.Failure?
    @State private var importing = false
    @FocusState private var linkFocused: Bool

    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "upload")

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        return types
    }()

    private var trimmedLink: String { link.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canContinue: Bool { picked != nil || !trimmedLink.isEmpty }

    var body: some View {
        OnboardingScaffold(stageIndex: 0, onBack: onBack) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("YOUR STORY · 1 OF 3")
                Text("Add your CV\nor portfolio.")
                    .atlasText(.display)
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Canopy reads it and builds your profile — no forms. Upload a file, or paste a link to your CV or portfolio.")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy600)
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
                        .foregroundStyle(Color.sunDeep)
                }
            }

            orDivider

            VStack(alignment: .leading, spacing: Space.s) {
                linkField
                Text("A CV or portfolio link — personal site, Behance, Dribbble, Google Scholar. Canopy reads it.")
                    .atlasText(.caption)
                    .foregroundStyle(Color.canopy400)
            }
        } bottom: {
            AtlasButton("Continue →", isEnabled: canContinue) {
                if let picked {
                    onContinue(.file(picked))
                } else if !trimmedLink.isEmpty {
                    onContinue(.link(trimmedLink))
                }
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: Self.allowedTypes,
                      allowsMultipleSelection: false,
                      onCompletion: handleImport)
    }

    // MARK: Drop zone / file row

    private var dropZone: some View {
        Button {
            // Hosted previews (Appetize) have no real Files access — attach a
            // sample CV so the reviewer can walk the flow instead of hitting a
            // dead-end picker. Real device builds open the picker.
            if Config.demoMode {
                picked = PickedCV(filename: "Alex_Rivera_Resume.pdf", byteSize: 248_000, data: Data())
            } else {
                importing = true
            }
        } label: {
            VStack(spacing: Space.m) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Color.canopyMist)
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "arrow.up.doc")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.canopy600))
                Text("Upload your CV or portfolio").atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                Text("PDF or DOCX · tap to browse").atlasText(.caption).foregroundStyle(Color.canopy400)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(Color.canopyPaperDeep)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Color.canopyPaperLine, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
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
                    .foregroundStyle(Color.canopy600)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cv.filename).atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                        .lineLimit(1).truncationMode(.middle)
                    Text(byteCount(cv.byteSize)).atlasText(.caption).foregroundStyle(Color.canopy400)
                }
                Spacer()
                Button("Replace") { if Config.demoMode { picked = nil } else { importing = true } }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.canopy600)
            }
        }
    }

    private var linkField: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "link").font(.system(size: 15)).foregroundStyle(Color.canopy400)
            TextField("Paste a link", text: $link)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.done)
                .focused($linkFocused)
                .font(.system(size: 16))
                .foregroundStyle(Color.canopy900)
        }
        .padding(.horizontal, Space.l)
        .frame(height: 54)
        .background(Color.canopyPaperDeep)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                .strokeBorder(linkFocused ? Color.canopy600 : Color.canopyPaperLine, lineWidth: 1)
        )
    }

    private var orDivider: some View {
        HStack(spacing: Space.m) {
            Rectangle().fill(Color.canopyPaperLine).frame(height: 1)
            Text("or").atlasText(.caption).foregroundStyle(Color.canopy400)
            Rectangle().fill(Color.canopyPaperLine).frame(height: 1)
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
    UploadCVView(onContinue: { _ in })
}
