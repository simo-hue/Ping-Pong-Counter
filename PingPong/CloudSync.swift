import Foundation

/// Mirrors match history and the player roster through iCloud's key-value store.
///
/// Availability is genuinely hard to detect, and getting it wrong either way is bad: claim it works
/// when it does not and the user's matches quietly go nowhere; claim it does not when it does and a
/// working feature stays hidden. `NSUbiquitousKeyValueStore.default` is never nil, so the object
/// itself proves nothing. `synchronize()` IS a real signal — it returns false when the
/// `com.apple.developer.ubiquity-kvstore-identifier` entitlement is missing — so that is the probe.
///
/// Deliberately NOT probed with `FileManager.ubiquityIdentityToken`: that token describes iCloud
/// *Drive / ubiquity-container* identity, which this app neither uses nor is entitled to. An earlier
/// version required it and so reported "iCloud unavailable" on devices whose key-value store worked
/// perfectly well.
final class CloudSync {
    static let shared = CloudSync()

    /// The store caps both a single key and the whole store at 1 MB. History is trimmed to fit
    /// rather than being rejected wholesale.
    private static let recordsByteBudget = 700_000

    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?
    private var onRemoteChange: (() -> Void)?

    /// Only history and the roster travel. Live match state deliberately does not: two phones
    /// scoring the same rally would fight, and the match is over in minutes.
    private enum Key {
        static let matchRecords = PersistenceKeys.matchRecords
        static let roster = PersistenceKeys.roster
        static let deletedMatchIds = PersistenceKeys.deletedMatchIds
        static let deletedRosterIds = PersistenceKeys.deletedRosterIds
    }

    private init() {}

    /// Whether iCloud accepted a sync request. Availability is NOT consent.
    private(set) var isAvailable = false

    /// Whether the user has sync switched on. `push()` checks this, so merely probing availability —
    /// which the settings screen does — can never start uploading.
    private(set) var isRunning = false

    @discardableResult
    func refreshAvailability() -> Bool {
        isAvailable = store.synchronize()
        return isAvailable
    }

    @discardableResult
    func start(onRemoteChange: @escaping () -> Void) -> Bool {
        guard refreshAvailability() else { return false }

        self.onRemoteChange = onRemoteChange

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] note in
            self?.handleExternalChange(note)
        }

        isRunning = true

        // The launch pull must take the same path as a remote change. Writing into the defaults is
        // not enough: the view model has already read them into memory, so without the callback the
        // next local write goes straight back over whatever was just downloaded.
        merge()
        onRemoteChange()

        // Deliberately NO push here. `synchronize()` returns before the store has necessarily
        // finished downloading, so an account switch made while the app was closed would upload the
        // previous account's history into the new one before any AccountChange notification arrives.
        // The first external-change notification settles which account this is; local edits push on
        // their own once it has.

        return true
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        onRemoteChange = nil
        isRunning = false
        isAvailable = false
    }

    /// Re-checks when the app returns to the foreground: the user may have signed into iCloud, or
    /// out of it, while the app was away.
    @discardableResult
    func refreshAfterForeground() -> Bool {
        guard isRunning else { return refreshAvailability() }

        guard refreshAvailability() else {
            stop()
            return false
        }

        merge()
        onRemoteChange?()
        return true
    }

    // MARK: - Change handling

    private func handleExternalChange(_ note: Notification) {
        let reason = (note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber)?.intValue

        switch reason {
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // Nothing arrived to merge — the store rejected our last write. Trim and retry rather
            // than leaving the remote copy permanently behind.
            push()
            return

        case NSUbiquitousKeyValueStoreAccountChange:
            // A different iCloud account is in play, and its records are not this user's. Adopt the
            // new account's copy wholesale: unioning here would fold a stranger's match history
            // into the local roster.
            adoptRemoteWholesale()

        default:
            merge()
            // The store has now told us which account it belongs to, so uploading is safe.
            push()
        }

        onRemoteChange?()
    }

    // MARK: - Merging

    /// Unions the remote copy into the local one and writes the result back locally.
    private func merge() {
        let defaults = SharedStore.defaults

        let deletedMatches = SyncMerge.cappedTombstones(
            localIDs(defaults, Key.deletedMatchIds).union(remoteIDs(Key.deletedMatchIds))
        )
        let deletedRoster = SyncMerge.cappedTombstones(
            localIDs(defaults, Key.deletedRosterIds).union(remoteIDs(Key.deletedRosterIds))
        )

        let mergedMatches = SyncMerge.mergeMatches(
            local: decode([MatchRecord].self, from: defaults.data(forKey: Key.matchRecords)) ?? [],
            remote: decode([MatchRecord].self, from: store.data(forKey: Key.matchRecords)) ?? [],
            deleted: deletedMatches
        )
        let mergedRoster = SyncMerge.mergeRoster(
            local: decode([RosterPlayer].self, from: defaults.data(forKey: Key.roster)) ?? [],
            remote: decode([RosterPlayer].self, from: store.data(forKey: Key.roster)) ?? [],
            deleted: deletedRoster
        )

        write(mergedMatches, to: defaults, key: Key.matchRecords)
        write(mergedRoster, to: defaults, key: Key.roster)
        writeIDs(deletedMatches, to: defaults, key: Key.deletedMatchIds)
        writeIDs(deletedRoster, to: defaults, key: Key.deletedRosterIds)
    }

    /// Replaces local state with the remote copy. Only for an iCloud account change.
    private func adoptRemoteWholesale() {
        let defaults = SharedStore.defaults

        if let data = store.data(forKey: Key.matchRecords) {
            defaults.set(data, forKey: Key.matchRecords)
        } else {
            defaults.removeObject(forKey: Key.matchRecords)
        }

        if let data = store.data(forKey: Key.roster) {
            defaults.set(data, forKey: Key.roster)
        } else {
            defaults.removeObject(forKey: Key.roster)
        }

        writeIDs(remoteIDs(Key.deletedMatchIds), to: defaults, key: Key.deletedMatchIds)
        writeIDs(remoteIDs(Key.deletedRosterIds), to: defaults, key: Key.deletedRosterIds)
    }

    // MARK: - Upload

    func push() {
        guard isRunning, isAvailable else { return }

        let defaults = SharedStore.defaults

        let records = decode([MatchRecord].self, from: defaults.data(forKey: Key.matchRecords)) ?? []
        let fitting = SyncMerge.recordsFitting(records, byteLimit: Self.recordsByteBudget)
        if let data = try? JSONEncoder().encode(fitting) {
            store.set(data, forKey: Key.matchRecords)
        }

        if let data = defaults.data(forKey: Key.roster) {
            store.set(data, forKey: Key.roster)
        }

        storeIDs(localIDs(defaults, Key.deletedMatchIds), key: Key.deletedMatchIds)
        storeIDs(localIDs(defaults, Key.deletedRosterIds), key: Key.deletedRosterIds)

        store.synchronize()
    }

    /// Records that an id was deliberately removed, so the deletion survives the next merge instead
    /// of being undone by a device that still holds the record.
    func recordDeletion(matchIDs: [UUID] = [], rosterIDs: [UUID] = []) {
        let defaults = SharedStore.defaults

        if !matchIDs.isEmpty {
            let merged = SyncMerge.cappedTombstones(localIDs(defaults, Key.deletedMatchIds).union(matchIDs))
            writeIDs(merged, to: defaults, key: Key.deletedMatchIds)
        }
        if !rosterIDs.isEmpty {
            let merged = SyncMerge.cappedTombstones(localIDs(defaults, Key.deletedRosterIds).union(rosterIDs))
            writeIDs(merged, to: defaults, key: Key.deletedRosterIds)
        }

        push()
    }

    // MARK: - Coding helpers

    private func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<T: Encodable>(_ value: T, to defaults: UserDefaults, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func localIDs(_ defaults: UserDefaults, _ key: String) -> Set<UUID> {
        Set((defaults.array(forKey: key) as? [String] ?? []).compactMap(UUID.init(uuidString:)))
    }

    private func remoteIDs(_ key: String) -> Set<UUID> {
        Set((store.array(forKey: key) as? [String] ?? []).compactMap(UUID.init(uuidString:)))
    }

    private func writeIDs(_ ids: Set<UUID>, to defaults: UserDefaults, key: String) {
        defaults.set(ids.map(\.uuidString), forKey: key)
    }

    private func storeIDs(_ ids: Set<UUID>, key: String) {
        store.set(ids.map(\.uuidString), forKey: key)
    }
}
