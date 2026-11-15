import Foundation
import QuartzCore

/// Counts frames that arrived later than the display's refresh interval.
@MainActor
final class FrameMonitor: NSObject {
    private(set) var droppedFrames = 0
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        let newLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        newLink.add(to: .main, forMode: .common)
        link = newLink
    }

    func stop() {
        link?.invalidate()
        link = nil
        lastTimestamp = 0
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        let interval = displayLink.targetTimestamp - displayLink.timestamp
        if lastTimestamp > 0, interval > 0 {
            let missed = Int(((displayLink.timestamp - lastTimestamp) / interval).rounded()) - 1
            if missed > 0 { droppedFrames += missed }
        }
        lastTimestamp = displayLink.timestamp
    }
}
