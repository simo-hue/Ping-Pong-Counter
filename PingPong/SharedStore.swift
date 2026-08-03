import Foundation

/// The defaults database the app reads and writes.
///
/// A Home Screen widget runs in its own process and cannot see the app's `UserDefaults.standard`,
/// so sharing state with one requires an App Group. That group is a signing capability, and this
/// project does not currently declare it.
///
/// The trap: `UserDefaults(suiteName:)` returns a perfectly good object for ANY `group.*` name,
/// entitled or not — it is nil only for the app's own bundle identifier or the global domain. So
/// it cannot be used to detect whether the group exists. Relying on it would silently move every
/// write into a domain the app is not entitled to, where the system rejects the writes and the
/// user's history quietly disappears on a signed build.
///
/// The only honest probe is asking the file system for the container, which is what this does. No
/// entitlement, no container, and everything stays on `.standard` exactly as before.
enum SharedStore {
    /// Must match the App Group added to both the app and the widget extension in Xcode.
    static let appGroupIdentifier = "group.com.simo.pingpong"

    /// Bumped whenever the migration itself changes, so a fixed migration can re-run for users who
    /// already went through a previous version of it.
    private static let migrationVersion = 1
    private static let migrationVersionKey = "sharedStoreMigrationVersion"

    /// True only when the entitlement is genuinely in place and provisioned.
    static var isSharedContainerAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) != nil
    }

    private static let resolved: UserDefaults = {
        guard isSharedContainerAvailable,
              let group = UserDefaults(suiteName: appGroupIdentifier) else {
            return .standard
        }

        migrateIfNeeded(into: group)
        return group
    }()

    static var defaults: UserDefaults { resolved }

    /// Copies anything the app has already saved into the shared container the first time it
    /// becomes available, so enabling the capability does not look like the user lost everything.
    private static func migrateIfNeeded(into group: UserDefaults) {
        guard group.integer(forKey: migrationVersionKey) < migrationVersion else { return }

        let standard = UserDefaults.standard
        for key in PersistenceKeys.all where group.object(forKey: key) == nil {
            if let value = standard.object(forKey: key) {
                group.set(value, forKey: key)
            }
        }

        group.set(migrationVersion, forKey: migrationVersionKey)
    }
}
