import Foundation
import UniformTypeIdentifiers

/// Serialises match history for sharing out of the app.
///
/// CSV for spreadsheets, JSON for anything that wants the full structure including the set scores
/// and rally logs the CSV flattens away.
enum MatchExport {
    enum Format: String, CaseIterable, Identifiable {
        case csv
        case json

        var id: String { rawValue }

        var fileExtension: String { rawValue }

        var contentType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }

        var displayName: String {
            switch self {
            case .csv: return "CSV"
            case .json: return "JSON"
            }
        }
    }

    /// Semicolon-separated, because the localized fields can themselves contain commas and most
    /// European spreadsheet locales expect the semicolon anyway.
    static func csv(from records: [MatchRecord]) -> String {
        let header = Localized.exportHeaders.map(quoted).joined(separator: ";")

        return ([header] + records.map(row)).joined(separator: "\n")
    }

    /// Built step by step rather than as one array literal: the mixed interpolations and ternaries
    /// in a single literal push the type-checker into an exponential search.
    private static func row(for record: MatchRecord) -> String {
        var fields: [String] = []
        fields.append(record.date.formatted(date: .abbreviated, time: .shortened))
        fields.append(record.p1Name)
        fields.append(record.p2Name)
        fields.append("\(record.p1Sets)-\(record.p2Sets)")
        fields.append("\(record.p1Score)-\(record.p2Score)")
        fields.append(record.setScoreLine ?? "-")
        fields.append(winnerName(for: record) ?? "-")
        fields.append(record.winner == nil ? Localized.interruptedMatch : Localized.completedMatch)
        fields.append(record.formattedDuration ?? "-")
        fields.append(
            Localized.exportRulesSummary(
                targetScore: record.targetScore,
                bestOfSets: record.bestOfSets,
                winByTwo: record.winByTwo
            )
        )

        return fields.map(quoted).joined(separator: ";")
    }

    static func json(from records: [MatchRecord]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(records),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return text
    }

    static func contents(of format: Format, records: [MatchRecord]) -> String {
        switch format {
        case .csv: return csv(from: records)
        case .json: return json(from: records)
        }
    }

    static func suggestedFileName(for format: Format, date: Date) -> String {
        let stamp = date.formatted(.iso8601.year().month().day())
        return "ping-pong-\(stamp).\(format.fileExtension)"
    }

    /// Writes the export to a temporary file so it can be handed to a share sheet as a real
    /// document — sharing a raw String offers only "copy", which is what the app already did.
    static func writeTemporaryFile(
        format: Format,
        records: [MatchRecord],
        date: Date = Date()
    ) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(suggestedFileName(for: format, date: date))

        do {
            try contents(of: format, records: records).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func quoted(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func winnerName(for record: MatchRecord) -> String? {
        switch record.winner {
        case .player1: return record.p1Name
        case .player2: return record.p2Name
        case nil: return nil
        }
    }
}
