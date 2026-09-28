import AppKit
import Testing
@testable import InputRelay

@MainActor
struct PermissionManagerTests {
    @Test func reflectsGrantsAndRevocations() {
        var trusted = false
        let manager = PermissionManager(accessibilityCheck: { trusted })
        #expect(!manager.allPermissionsGranted)
        trusted = true
        manager.checkPermissions()
        #expect(manager.allPermissionsGranted)
        trusted = false
        manager.checkPermissions()
        #expect(!manager.allPermissionsGranted)
    }

    @Test func returningFromSystemSettingsRefreshesPermission() {
        var trusted = false
        let manager = PermissionManager(accessibilityCheck: { trusted })
        manager.startMonitoring()
        manager.startMonitoring()
        trusted = true
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        #expect(manager.allPermissionsGranted)
        trusted = false
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        #expect(!manager.allPermissionsGranted)
    }
}
