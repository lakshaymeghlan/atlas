import SwiftUI
import os

/// S04 · Analysing. The river moment. Cannot be dismissed — no nav, no back.
/// Runs the parser, holds the river for at least 2.5s so a fast result never
/// reads as fake, and shows a proper in-place failure state.
struct AnalysingView: View {
    let source: CVSource
    var onFinished: () -> Void
    var onRetry: () -> Void
    var onManualEntry: () -> Void

    @Environment(ProfileStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var failed = false
    @State private var isLongRunning = false

    private let log = Logger(subsystem: "canopy.ai", category: "analysing")

    var body: some View {
        ZStack {
            Color.canopyPaper.ignoresSafeArea()
            if failed {
                failureState
            } else {
                working
            }
        }
        .task { await run() }
        .task { await watchForLongRun() }
    }

    private var working: some View {
        ZStack {
            RiverCanvas(isLongRunning: isLongRunning)
                .ignoresSafeArea()
            Text("Getting to know\nyour experience.")
                .atlasText(.display)
                .foregroundStyle(Color.canopy900)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 72)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var failureState: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Spacer()
            Text("That one didn't parse.")
                .atlasText(.display)
                .foregroundStyle(Color.canopy900)
                .fixedSize(horizontal: false, vertical: true)
            Text("Some PDFs are images rather than text. Try a different export, or add your details by hand.")
                .atlasText(.body)
                .foregroundStyle(Color.canopy600)
            Spacer()
            VStack(spacing: Space.m) {
                AtlasButton("Try another file", action: onRetry)
                AtlasButton("Enter manually", kind: .secondary, action: onManualEntry)
            }
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .transition(.opacity)
    }

    private func run() async {
        // Hold the river for at least 2.5s even if the parse returns sooner.
        async let floor: () = Task.sleep(for: .seconds(2.5))
        do {
            let result = try await MockCVParser.parse(source)
            try? await floor
            store.apply(result, email: auth.user?.email)
            log.info("Parse succeeded")
            onFinished()
        } catch {
            log.error("Parse failed: \(error.localizedDescription, privacy: .public)")
            withAnimation(Motion.standard(0.3)) { failed = true }
        }
    }

    private func watchForLongRun() async {
        try? await Task.sleep(for: .seconds(12))
        if !Task.isCancelled && !failed { isLongRunning = true }
    }
}

#Preview {
    AnalysingView(source: .file(PickedCV(filename: "cv.pdf", byteSize: 1000, data: Data())),
                  onFinished: {}, onRetry: {}, onManualEntry: {})
        .environment(ProfileStore())
        .environment(AuthStore())
}
