import SwiftUI

/// Hosts the current journey screen and animates state changes as a 24pt
/// downstream push + fade (a 160ms fade under Reduce Motion).
struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            content
                .id(stateID)
                .transition(Motion.screenTransition)
        }
        .animation(Motion.screenTransitionAnimation, value: stateID)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge) // support up to XXL; cap so layouts hold
    }

    @ViewBuilder private var content: some View {
        switch router.state {
        case .launching:
            Color.clear
        case .welcome:
            WelcomeView(onSignedIn: router.didSignIn)
        case .careerPath:
            CareerPathView(onChooseSeeking: router.chooseSeeking)
        case .uploadCV:
            UploadCVView(onContinue: router.didPickCV, onBack: router.backToCareerPath)
        case .analysing(let cv):
            AnalysingView(cv: cv,
                          onFinished: router.parsingSucceeded,
                          onRetry: router.retryUpload,
                          onManualEntry: router.enterManualEntry)
        case .confirmProfile:
            ConfirmProfileView(onDone: router.didConfirmProfile)
        case .home:
            HomeView(onSignOut: router.signOut)
        }
    }

    /// A stable identity per screen so the transition fires on change but not on
    /// in-screen updates (the analysing CV bytes don't restart the transition).
    private var stateID: Int {
        switch router.state {
        case .launching: return 0
        case .welcome: return 1
        case .careerPath: return 2
        case .uploadCV: return 3
        case .analysing: return 4
        case .confirmProfile: return 5
        case .home: return 6
        }
    }
}
