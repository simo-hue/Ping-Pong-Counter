import Foundation

/// Reconciles two copies of the synced collections.
///
/// The obvious implementation — whichever device wrote last wins the whole array — quietly destroys
/// data: two people play a match each while offline, both sync, and one match is gone from every
/// device and from iCloud. Match history is append-mostly and every record already carries a stable
/// `id`, so a union is both possible and correct.
///
/// Deletions then need to be represented explicitly, because "absent from my copy" and "deleted by
/// me" look identical in a union. Hence tombstones: the ids the user removed travel alongside the
/// records and are subtracted from the union, so a delete propagates instead of being undone by the
/// next device that still has the record.
///
/// Kept free of iCloud so it can be exercised by the offline model checks.
enum SyncMerge {
    /// Union by id, minus tombstones, newest first.
    static func mergeMatches(
        local: [MatchRecord],
        remote: [MatchRecord],
        deleted: Set<UUID>
    ) -> [MatchRecord] {
        var byID: [UUID: MatchRecord] = [:]

        // Remote first so a local copy of the same id wins — they are immutable once written, so
        // this only matters if a record was somehow rewritten.
        for record in remote { byID[record.id] = record }
        for record in local { byID[record.id] = record }

        // Tie-broken on id so two devices holding the same records always produce byte-identical
        // output — convergence becomes a property of the merge rather than an accident of the
        // timestamps happening to be unique.
        return byID.values
            .filter { !deleted.contains($0.id) }
            .sorted(by: newestFirst)
    }

    /// Written out rather than as a ternary inside `sorted`: the inline form sent the type-checker
    /// into an exponential search.
    private static func newestFirst(_ lhs: MatchRecord, _ rhs: MatchRecord) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    /// Union by id, minus tombstones. Where both sides hold the same player, the more recently
    /// edited entry wins — a rename on one device must not be reverted by a device that merely
    /// still has the old name.
    static func mergeRoster(
        local: [RosterPlayer],
        remote: [RosterPlayer],
        deleted: Set<UUID>
    ) -> [RosterPlayer] {
        var byID: [UUID: RosterPlayer] = [:]

        for player in remote + local {
            guard let existing = byID[player.id] else {
                byID[player.id] = player
                continue
            }
            byID[player.id] = player.lastEdited >= existing.lastEdited ? player : existing
        }

        return byID.values
            .filter { !deleted.contains($0.id) }
            .sorted(by: newestCreatedFirst)
    }

    private static func newestCreatedFirst(_ lhs: RosterPlayer, _ rhs: RosterPlayer) -> Bool {
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    /// Tombstones accumulate forever otherwise. A few thousand UUIDs is trivial next to the 1 MB
    /// key-value budget, but the cap keeps a pathological history from ever crowding out the
    /// records themselves.
    static func cappedTombstones(_ ids: Set<UUID>, limit: Int = 2000) -> Set<UUID> {
        guard ids.count > limit else { return ids }
        return Set(ids.sorted { $0.uuidString < $1.uuidString }.suffix(limit))
    }

    /// Trims history to fit the key-value store, dropping the oldest first. Returning fewer records
    /// than it was given is the signal that something was left behind.
    ///
    /// Binary search rather than "encode, drop one, encode again": the encoded size of a JSON array
    /// grows monotonically with the prefix length, so the largest fitting prefix can be found in
    /// ~log n encodes instead of one per dropped record. The naive loop cost ~1,000 full encodes of
    /// a 1,000-record array — seconds on the main actor, and this runs on every archived match.
    static func recordsFitting(
        _ records: [MatchRecord],
        byteLimit: Int,
        encoder: JSONEncoder = JSONEncoder()
    ) -> [MatchRecord] {
        let sorted = records.sorted { $0.date > $1.date }

        func fits(_ count: Int) -> Bool {
            guard let data = try? encoder.encode(Array(sorted.prefix(count))) else { return false }
            return data.count <= byteLimit
        }

        if fits(sorted.count) { return sorted }

        var low = 0
        var high = sorted.count
        while low < high {
            let mid = (low + high + 1) / 2
            if fits(mid) { low = mid } else { high = mid - 1 }
        }

        return Array(sorted.prefix(low))
    }
}
