import SwiftUI

@main
struct AtlasApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light) // Dark mode deferred to Phase 2
        }
    }
}
