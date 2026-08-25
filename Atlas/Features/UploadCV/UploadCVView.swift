import SwiftUI
import UniformTypeIdentifiers
import os

/// S03 · Bring your experience in. Upload a CV/portfolio file, connect LinkedIn,
/// or both — Canopy reads whatever you give it and builds the profile. The two
/// inputs are independent (not either/or); Continue unlocks once at least one is
/// provided.
struct UploadCVView: View {
    var onContinue: (CVSource) -> Void
    var onBack: (() -> Void)? = nil

    @State private var picked: PickedCV?
    @State private var validationError: CVValidation.Failure?
    @State private var importing = false

    private let log = Logger(subsystem: "canopy.ai", category: "upload")

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        return types
    }()

    private var canContinue: Bool { picked != nil }

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
                if Config.demoMode { sampleRow }
                linkedInCard
            }
        } bottom: {
            AtlasButton("Continue →", isEnabled: canContinue) {
                if let picked { onContinue(.file(picked)) }
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: Self.allowedTypes,
                      allowsMultipleSelection: false,
                      onCompletion: handleImport)
    }

    // MARK: Upload

    /// Bundled CVs, for testing without a file on the device. Real PDFs — tapping
    /// one goes through the same validation and file row as a picked document.
    private var sampleRow: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("Or try a sample")
                .atlasText(.caption)
                .foregroundStyle(Color.canopy400)
            FlowLayout(spacing: Space.s) {
                ForEach(SampleCV.allCases) { sample in
                    Button { attach(sample) } label: {
                        Text(sample.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.canopy600)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(Color.canopyMist))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use sample: \(sample.label)")
                }
            }
        }
    }

    private func attach(_ sample: SampleCV) {
        validationError = nil
        guard let cv = sample.load() else {
            log.error("Sample \(sample.filename, privacy: .public) missing from the bundle")
            return
        }
        if let failure = CVValidation.validate(filename: cv.filename, byteSize: cv.byteSize) {
            validationError = failure
            return
        }
        picked = cv
    }

    private var dropZone: some View {
        Button {
            // Hosted previews (Appetize) have no real Files access — attach a
            // bundled sample so a reviewer can walk the flow instead of hitting
            // a dead-end picker. Real device builds open the picker.
            if Config.demoMode {
                attach(.conventional)
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

    /// LinkedIn publishes no API for experience — their OIDC scopes return name,
    /// email and picture only. The import that actually works is the profile PDF
    /// the person exports, which is just another CV as far as parsing goes.
    private var linkedInCard: some View {
        Button {
            if Config.demoMode { attach(.linkedIn) } else { importing = true }
        } label: {
            HStack(spacing: Space.m) {
                BrandMarkView(mark: .linkedIn, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import from LinkedIn")
                        .atlasText(.bodyStrong).foregroundStyle(Color.canopy900)
                    Text("On LinkedIn: Profile → Resources → Save to PDF, then pick it here")
                        .atlasText(.caption).foregroundStyle(Color.canopy400)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Space.s)
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.canopy400)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.canopyPaperDeep)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Color.canopyPaperLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Import your LinkedIn profile PDF")
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

        // Judge it on the advertised type + size *before* reading: a 2 GB "CV"
        // must not be pulled into memory just to be turned down. When the size
        // isn't advertised, pass the limit so only the type gates here and the
        // empty case is caught on the read below.
        let filename = url.lastPathComponent
        let declaredSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        if let failure = CVValidation.validate(filename: filename,
                                              byteSize: declaredSize ?? CVValidation.maxBytes) {
            validationError = failure
            picked = nil
            return
        }
        guard let data = try? Data(contentsOf: url), !data.isEmpty else {
            validationError = .empty
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
