import Foundation

struct MappingInputCapture {
    private(set) var selectedButton: GamepadButton?
    private(set) var isWaiting = false
    private var heldAtStart: Set<GamepadButton> = []

    init(selectedButton: GamepadButton? = nil) {
        self.selectedButton = selectedButton
    }

    mutating func begin(heldButtons: Set<GamepadButton>) {
        heldAtStart = heldButtons
        isWaiting = true
    }

    mutating func stop() { isWaiting = false }

    mutating func select(_ button: GamepadButton) {
        guard !button.isStickAxis else { return }
        selectedButton = button
        isWaiting = false
    }

    mutating func receive(_ event: GamepadEvent) {
        if !event.isPressed {
            heldAtStart.remove(event.button)
            return
        }
        guard isWaiting, !heldAtStart.contains(event.button), !event.button.isStickAxis else { return }
        select(event.button)
    }
}
