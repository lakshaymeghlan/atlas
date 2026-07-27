import SwiftUI

/// Host view. In Step 1 it's just the paper background; AppRouter takes over
/// here in Step 6.
struct RootView: View {
    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
        }
    }
}

#Preview {
    RootView()
}
