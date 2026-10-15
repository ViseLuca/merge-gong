import Foundation
import ServiceManagement

/// Opening the app at login, through the system's Login Items.
enum LoginItem {
    private static var service: SMAppService { .mainApp }

    /// Only an app bundle can be a login item, not a `swift run` binary.
    static var isAvailable: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    static var isEnabled: Bool { service.status == .enabled }

    /// Registered, but switched off in System Settings.
    static var needsApproval: Bool { service.status == .requiresApproval }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled { try service.register() } else { try service.unregister() }
    }

    /// Registers again if it was wanted but the registration is gone, as can happen when an update replaces the app.
    /// Turning it off in System Settings leaves it `requiresApproval`, not `notRegistered`, so that choice stands.
    static func restore(wanted: Bool) {
        guard wanted, isAvailable, service.status == .notRegistered else { return }
        try? service.register()
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
