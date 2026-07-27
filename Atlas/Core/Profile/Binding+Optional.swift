import SwiftUI

extension Binding where Value == String? {
    /// Bridge an optional-String model field to a TextField. Empty input maps
    /// back to nil so blank fields stay null (never a guessed value).
    var orEmpty: Binding<String> {
        Binding<String>(
            get: { wrappedValue ?? "" },
            set: { wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
