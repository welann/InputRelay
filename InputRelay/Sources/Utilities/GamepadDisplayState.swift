import AppKit
import Combine

/// Only the visible status page observes these snapshots; input processing never waits for UI refresh.
@MainActor
final class GamepadDisplayState: ObservableObject {
    private(set) var buttonStates: [GamepadButton: Float] = [:]
    private(set) var leftStick = SIMD2<Float>.zero
    private(set) var rightStick = SIMD2<Float>.zero
    private(set) var lastEvent: GamepadEvent?

    func refresh(from manager: GamepadManager) {
        objectWillChange.send()
        buttonStates = manager.buttonStates
        leftStick = manager.leftStick
        rightStick = manager.rightStick
        lastEvent = manager.lastEvent
    }

    func getButtonState(_ button: GamepadButton) -> Float { buttonStates[button] ?? 0 }
    func getStickAxes(isLeft: Bool) -> (x: Float, y: Float) {
        let axes = isLeft ? leftStick : rightStick
        return (axes.x, axes.y)
    }
}
