import CoreGraphics
import Foundation

/// Keep whole press/release sequences ordered off the input/UI thread.
/// A serial queue also prevents overlapping shortcuts from releasing each other's modifiers.
enum InputEventSequence {
    private static let queue = DispatchQueue(label: "InputRelay.event-sequences", qos: .userInteractive)

    static func post(_ events: [CGEvent], pauseBefore: Int, delay: TimeInterval = 0.01,
                     emit: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) }) {
        queue.async(execute: DispatchWorkItem {
            for (index, event) in events.enumerated() {
                if index == pauseBefore { Thread.sleep(forTimeInterval: delay) }
                emit(event)
            }
        })
    }
}
