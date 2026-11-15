import UIKit
import Core

/// UIKit haptics; the view models call it on the main thread.
struct HapticsAdapter: HapticsService {
    func success() {
        MainActor.assumeIsolated {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func gentle() {
        MainActor.assumeIsolated {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
