import Foundation

/// Mirrors match history and the player roster through iCloud's key-value store.
///
/// Like the App Group, this needs a capability the project does not currently declare, and like
/// `UserDefaults(suiteName:)` the API gives no honest signal at construction time —
/// `NSUbiquitousKeyValueStore.default` always returns an object. The real signal is
/// `synchronize()`, which returns false when the entitlement or the account is missing.
///
/// So syncing stays off unless it is proven to work, and the setting that exposes it is hidden
/// when it cannot. Nothing silently half-syncs.
final class CloudSync {
    static let shared = CloudSync()

    /// The store is capped at 1 MB total and 1 MB per key; history well past a thousand matches
    /// stays far inside that, but the write is guarded anyway rather than failing invisibly.
    private static let valueSizeLimit = 900_000

    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    /// Keys worth carrying between devices. Live match state deliberately is not — two phones
    /// scoring the same rally would fight, and the match is over in minutes anyway.
    ///
    /// Deliberately just these two. Everything else the app persists is held in memory as a
    /// @Published property that is only read at launch, so pulling a remote value into the defaults
    /// would leave the UI showing the stale one — and the next local edit would write it back over
    /// the remote copy. Syncing only what the app can genuinely reload keeps that impossible.
    private static let syncedKeys = [
        PersistenceKeys.matchRecords,
        PersistenceKeys.roster
    ]

    private init() {}

    /// True only when iCloud actually accepted a sync request. Availability alone is NOT consent.
    private(set) var isAvailable = false

    /// True only while the user has sync switched on. `push()` checks this, not availability —
    /// otherwise merely opening Settings (which probes availability) would start uploading, and
    /// switching sync off would not stop it.
    private(set) var isRunning = false

    /// Probes the store once. Cheap, and the result decides whether the UI offers the setting.
    @discardableResult
    func refreshAvailability() -> Bool {
        isAvailable = FileManager.default.ubiquityIdentityToken != nil && store.synchronize()
        return isAvailable
    }

    /// Starts mirroring. Returns false when iCloud is unavailable, so the caller can turn the
    /// setting back off rather than leave it looking enabled.
    @discardableResult
    func start(onRemoteChange: @escaping () -> Void) -> Bool {
        guard refreshAvailability() else { return false }

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.pullRemoteChanges()
            onRemoteChange()
        }

        // Take the same path a remote change would: pulling into the defaults is not enough,
        // because the view model has already read them into memory. Without this the next local
        // write overwrites whatever was just downloaded.
        pullRemoteChanges()
        onRemoteChange()

        isRunning = true
        return true
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        isRunning = false
        isAvailable = false
    }

    /// Pushes the local copy of the synced keys upwards.
    func push() {
        guard isRunning, isAvailable else { return }

        let defaults = SharedStore.defaults
        for key in Self.syncedKeys {
            guard let value = defaults.object(forKey: key) else {
                store.removeObject(forKey: key)
                continue
            }

            if let data = value as? Data, data.count > Self.valueSizeLimit {
                // Too large for the key-value store; leave the previous remote copy alone rather
                // than truncating the user's history.
                continue
            }

            store.set(value, forKey: key)
        }

        store.synchronize()
    }

    /// Copies whatever iCloud holds into the local store. Last writer wins, which is the right
    /// trade for a scoreboard: the alternative is a merge UI nobody wants mid-match.
    private func pullRemoteChanges() {
        let defaults = SharedStore.defaults
        for key in Self.syncedKeys {
            guard let value = store.object(forKey: key) else { continue }
            defaults.set(value, forKey: key)
        }
    }
}
