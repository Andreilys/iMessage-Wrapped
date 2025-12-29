import SwiftUI

@main
struct iMessageWrappedApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .frame(minWidth: 500, minHeight: 700)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .frame(minWidth: 500, minHeight: 700)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 700)
    }
}
