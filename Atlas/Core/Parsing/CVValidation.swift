import Foundation

/// Pre-upload validation for a picked CV. Pure and testable — no file I/O.
enum CVValidation {
    static let maxBytes = 10 * 1024 * 1024 // 10 MB

    enum Failure: Equatable {
        case tooLarge, wrongType, empty

        /// Inline copy shown under the drop zone (never an alert).
        var message: String {
            switch self {
            case .tooLarge: return "That file is over 10 MB. Try exporting a smaller PDF."
            case .wrongType: return "Atlas reads PDF and DOCX. Try exporting your CV again."
            case .empty: return "That file looks empty. Try exporting your CV again."
            }
        }
    }

    /// Returns the reason a file is rejected, or nil if it's acceptable.
    static func validate(filename: String, byteSize: Int) -> Failure? {
        let ext = (filename as NSString).pathExtension.lowercased()
        guard ext == "pdf" || ext == "docx" else { return .wrongType }
        guard byteSize > 0 else { return .empty }
        guard byteSize <= maxBytes else { return .tooLarge }
        return nil
    }
}
