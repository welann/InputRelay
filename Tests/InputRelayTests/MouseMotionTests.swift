import CoreGraphics
import Testing
@testable import InputRelay

struct MouseMotionTests {
    @Test func movementSpeedIsIndependentOfTickRate() {
        for frequency in [60, 120] {
            var cursor = CGPoint(x: 100, y: 100)
            let simulator = MouseSimulator(cursorLocation: { cursor },
                displayBounds: { [CGRect(x: 0, y: 0, width: 2000, height: 1000)] },
                postEvent: { cursor = $0.location })
            for _ in 0..<frequency {
                simulator.handleStickInput(x: 1, y: 0, sensitivity: 1,
                    curve: .linear, deadzone: 0.15, elapsed: 1.0 / Double(frequency))
            }
            #expect(abs(cursor.x - 700) <= 1)
        }
    }

    @Test func fractionalMovementSurvivesIntegerCursorPositions() {
        var cursor = CGPoint(x: 100, y: 100)
        let simulator = MouseSimulator(cursorLocation: { cursor }, displayBounds: { [] },
            postEvent: { cursor = CGPoint(x: $0.location.x.rounded(), y: $0.location.y.rounded()) })
        for _ in 0..<8 { simulator.moveMouse(dx: 0.25, dy: -0.25) }
        #expect(cursor == CGPoint(x: 102, y: 98))
    }

    @Test func scrollingAccumulatesFractionsAndResetsAtRest() {
        var events: [CGEvent] = []
        let simulator = MouseSimulator(cursorLocation: { .zero }, displayBounds: { [] },
            postEvent: { events.append($0) })
        for _ in 0..<10 { simulator.scroll(deltaY: 0.25) }
        #expect(events.count == 2)
        #expect(events.allSatisfy { $0.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == 1 })
        #expect(events.allSatisfy { $0.getIntegerValueField(.scrollWheelEventIsContinuous) == 1 })
        simulator.scroll(deltaY: 0)
        simulator.scroll(deltaY: 0.5)
        #expect(events.count == 2)
        simulator.scroll(deltaY: -0.5)
        simulator.scroll(deltaY: -0.5)
        #expect(events.last?.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == -1)
    }
}
