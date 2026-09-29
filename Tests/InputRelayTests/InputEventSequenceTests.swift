import CoreGraphics
import Foundation
import Testing
@testable import InputRelay

struct InputEventSequenceTests {
    @MainActor @Test func sequencesRunOffCallerAndStayOrdered() async throws {
        let events = try [0, 1, 2, 3].map { code in
            try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: code % 2 == 0))
        }
        let result: ([Int64], Bool) = await withCheckedContinuation { continuation in
            let caller = Thread.current
            var received: [Int64] = []
            var offCaller = true
            let collect: (CGEvent) -> Void = { event in
                offCaller = offCaller && Thread.current !== caller
                received.append(event.getIntegerValueField(.keyboardEventKeycode))
                if received.count == 4 { continuation.resume(returning: (received, offCaller)) }
            }
            InputEventSequence.post(Array(events.prefix(2)), pauseBefore: 1, emit: collect)
            InputEventSequence.post(Array(events.suffix(2)), pauseBefore: 1, emit: collect)
        }
        #expect(result.0 == [0, 1, 2, 3])
        #expect(result.1)
    }
}
