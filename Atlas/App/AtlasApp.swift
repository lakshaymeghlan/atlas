import SwiftUI

@main
struct AtlasApp: App {
    @State private var auth: AuthStore
    @State private var profile: ProfileStore
    @State private var router: AppRouter

    init() {
        let auth = AuthStore()
        let profile = ProfileStore()
        _auth = State(initialValue: auth)
        _profile = State(initialValue: profile)
        _router = State(initialValue: AppRouter(auth: auth, profile: profile))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(profile)
                .environment(router)
                .preferredColorScheme(.light) // Dark mode deferred to Phase 2
        }
    }
}
