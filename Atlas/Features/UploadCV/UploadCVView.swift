import SwiftUI
import UniformTypeIdentifiers
import os

/// S03 · Bring your experience in. Upload a CV/portfolio file, connect LinkedIn,
/// or both — Canopy reads whatever you give it and builds the profile. The two
/// inputs are independent (not either/or); Continue unlocks once at least one is
/// provided.
struct UploadCVView: View {
    var onContinue: (CVSource) -> Void
    var onSetLinkedIn: (Bool) -> Void = { _ in }
    var onBack: (() -> Void)? = nil

    @State private var picked: PickedCV?
    @State private var linkedInConnected = false
    @State private var validationError: CVValidation.Failure?
    @State private var importing = false

    private let log = Logger(subsystem: "canopy.ai", category: "upload")

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        return types
    }()

    private var canContinue: Bool { picked != nil || linkedInConnected }

    var body: some View {
        OnboardingScaffold(stageIndex: 0, onBack: onBack) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("YOUR STORY · 1 OF 9")
                Text("Bring your\nexperience in.")
                    .atlasText(.display)
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Canopy reads it and builds your profile — no forms. Add your CV, connect LinkedIn, or do both.")
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
                linkedInCard
            }
        } bottom: {
            AtlasButton("Continue →", isEnabled: canContinue) {
                if let picked {
                    onContinue(.file(picked))
                } else if linkedInConnected {
                    onContinue(.linkedIn)
                }
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: Self.allowedTypes,
                      allowsMultipleSelection: false,
                      onCompletion: handleImport)
    }

    // MARK: Upload

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
            .frame(height: 160)
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

    // MARK: LinkedIn

    private var linkedInCard: some View {
        Button {
            let now = !linkedInConnected
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { linkedInConnected = now }
            onSetLinkedIn(now)
        } label: {
            HStack(spacing: Space.m) {
                BrandMarkView(mark: .linkedIn, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(linkedInConnected ? "LinkedIn connected" : "Connect with LinkedIn")
                        .atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                    Text(linkedInConnected ? "Your experience and network are in" : "Import your experience and network")
                        .atlasText(.caption).foregroundStyle(Color.canopy400)
                }
                Spacer(minLength: Space.s)
                Image(systemName: linkedInConnected ? "checkmark.circle.fill" : "plus")
                    .font(.system(size: linkedInConnected ? 20 : 16, weight: .medium))
                    .foregroundStyle(linkedInConnected ? Color.canopy600 : Color.canopy400)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.canopyPaperDeep)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(linkedInConnected ? Color.canopy600 : Color.canopyPaperLine,
                                  lineWidth: linkedInConnected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(linkedInConnected ? "LinkedIn connected. Tap to disconnect." : "Connect with LinkedIn")
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
