import AppKit
import SwiftUI
import Testing
@testable import InputRelay

@MainActor
struct ButtonLayoutTests {
    @Test func faceButtonGlowDoesNotChangeLayoutSize() {
        let idle = NSHostingView(rootView: FaceButton(label: "Y", isPressed: false, color: .yellow))
        let pressed = NSHostingView(rootView: FaceButton(label: "Y", isPressed: true, color: .yellow))
        #expect(idle.fittingSize == pressed.fittingSize)
        #expect(pressed.fittingSize == NSSize(width: 36, height: 36))
    }

    @Test func mappingButtonGlowDoesNotChangeLayoutSize() {
        let idle = NSHostingView(rootView: ButtonIndicator(label: "A", isPressed: false))
        let pressed = NSHostingView(rootView: ButtonIndicator(label: "A", isPressed: true))
        #expect(idle.fittingSize == pressed.fittingSize)
        #expect(pressed.fittingSize == NSSize(width: 40, height: 40))
    }
}
