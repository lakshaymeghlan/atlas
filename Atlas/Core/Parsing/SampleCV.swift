import Foundation

/// CVs bundled with the app for testing the upload path without hunting for a
/// file. These are real PDFs with real bytes, so validation, the byte-size row,
/// and (once the backend is wired) the actual upload all see a genuine document
/// rather than a placeholder.
///
/// Shown only in `Config.demoMode`. The same files live in
/// `Atlas/Resources/SampleCVs/` and are what the edge-function tests run against.
enum SampleCV: String, CaseIterable, Identifiable {
    case conventional = "Alex_Rivera_CV"
    case linkedIn = "LinkedIn_Profile_Export"
    /// An image-only PDF — no text layer, so it exercises the failure state.
    case scan = "Scanned_CV_image"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .conventional: "CV"
        case .linkedIn: "LinkedIn"
        case .scan: "Scan (fails)"
        }
    }

    var filename: String { "\(rawValue).pdf" }

    /// Load the bundled PDF. Returns nil if it wasn't copied into the bundle.
    func load() -> PickedCV? {
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "pdf"),
              let data = try? Data(contentsOf: url), !data.isEmpty
        else { return nil }
        return PickedCV(filename: filename, byteSize: data.count, data: data)
    }
}
