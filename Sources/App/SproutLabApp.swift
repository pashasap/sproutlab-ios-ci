import SwiftUI
import Core

@main
struct SproutLabApp: App {
    @State private var environment = AppEnvironment(
        audit: AuditLaunch.resolve(argument: UserDefaults.standard.string(forKey: "auditStop")))
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
                .onAppear { environment.didLaunch() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { environment.app.sceneDidEnterBackground() }
            if phase != .inactive { environment.music.scenePhaseChanged(background: phase == .background) }
        }
    }
}
