import SwiftUI

/// Manages saved competitors and, when presented as a picker, assigns one to a side of the table.
struct RosterView: View {
    @ObservedObject var viewModel: ScoreViewModel

    /// When set, the screen acts as a picker for that side and dismisses on selection.
    /// When nil it is a plain management screen.
    var assigningTo: Player?
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftEmoji = RosterPlayer.defaultEmoji
    @State private var editingPlayer: RosterPlayer?
    @State private var duplicateNameWarning = false

    private var theme: AppTheme { AppTheme.theme(at: viewModel.themeIndex) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Form {
                addSection

                if viewModel.roster.isEmpty {
                    Section {
                        emptyState.listRowBackground(Color(white: 0.15))
                    }
                } else {
                    Section(header: Text(Localized.savedPlayersHeader).foregroundColor(.gray)) {
                        ForEach(viewModel.roster) { player in
                            rosterRow(player)
                                .listRowBackground(Color(white: 0.15))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteRosterPlayer(id: player.id)
                                    } label: {
                                        Label(Localized.deleteRecord, systemImage: "trash.fill")
                                    }

                                    Button {
                                        editingPlayer = player
                                    } label: {
                                        Label(Localized.editPlayer, systemImage: "pencil")
                                    }
                                    .tint(.indigo)
                                }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(assigningTo == nil ? Localized.rosterTitle : Localized.choosePlayerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPlayer) { player in
            NavigationStack {
                RosterPlayerEditor(player: player) { updated in
                    viewModel.updateRosterPlayer(updated)
                }
                .id(player.id)
            }
            .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Add

    private var addSection: some View {
        Section {
            HStack(spacing: 10) {
                Menu {
                    ForEach(RosterPlayer.emojiChoices, id: \.self) { emoji in
                        Button(emoji) { draftEmoji = emoji }
                    }
                } label: {
                    Text(draftEmoji)
                        .font(.system(size: 22))
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }

                TextField(Localized.newPlayerPlaceholder, text: $draftName)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.words)
                    .onSubmit(addDraftPlayer)

                Button(action: addDraftPlayer) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(canAddDraft ? theme.p1Color : .white.opacity(0.2))
                }
                .buttonStyle(.plain)
                .disabled(!canAddDraft)
                .accessibilityLabel(Localized.addPlayer)
            }
            .listRowBackground(Color(white: 0.15))
        } header: {
            Text(Localized.addPlayer).foregroundColor(.gray)
        } footer: {
            if duplicateNameWarning {
                Text(Localized.duplicatePlayerWarning).foregroundColor(.orange)
            } else {
                Text(Localized.rosterFooter).foregroundColor(.gray)
            }
        }
    }

    private var canAddDraft: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addDraftPlayer() {
        guard canAddDraft else { return }

        if let created = viewModel.addRosterPlayer(name: draftName, emoji: draftEmoji) {
            duplicateNameWarning = false
            draftName = ""
            draftEmoji = RosterPlayer.defaultEmoji

            if let side = assigningTo {
                viewModel.assignRosterPlayer(created, to: side)
                finish()
            }
        } else {
            duplicateNameWarning = true
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func rosterRow(_ player: RosterPlayer) -> some View {
        let stats = viewModel.stats(for: player)

        if let side = assigningTo {
            Button {
                viewModel.assignRosterPlayer(player, to: side)
                finish()
            } label: {
                rosterRowContent(player, stats: stats, showsChevron: false)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                PlayerStatsView(player: player, viewModel: viewModel)
            } label: {
                rosterRowContent(player, stats: stats, showsChevron: true)
            }
        }
    }

    private func rosterRowContent(_ player: RosterPlayer, stats: PlayerStats, showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Text(player.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.07)))

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(Localized.playedWonSummary(played: stats.matchesPlayed, won: stats.matchesWon))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer(minLength: 6)

            if stats.decidedMatches > 0 {
                Text(stats.winRatePercentText)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundColor(theme.p1Color)
            }

            if !showsChevron, isOnTable(player) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.p2Color)
            }
        }
        .padding(.vertical, 3)
    }

    private func isOnTable(_ player: RosterPlayer) -> Bool {
        viewModel.p1RosterId == player.id || viewModel.p2RosterId == player.id
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.4))

            Text(Localized.noSavedPlayers)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    private func finish() {
        onDismiss?()
        dismiss()
    }
}

/// Rename / re-emoji an existing roster entry.
private struct RosterPlayerEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RosterPlayer
    @State private var showsDuplicateWarning = false
    /// Returns false when the edit collides with another saved player, so the sheet stays open.
    let onSave: (RosterPlayer) -> Bool

    init(player: RosterPlayer, onSave: @escaping (RosterPlayer) -> Bool) {
        _draft = State(initialValue: player)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section {
                TextField(Localized.newPlayerPlaceholder, text: $draft.name)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.words)
                    .listRowBackground(Color(white: 0.15))
            } header: {
                Text(Localized.editPlayer).foregroundColor(.gray)
            } footer: {
                if showsDuplicateWarning {
                    Text(Localized.duplicatePlayerWarning).foregroundColor(.orange)
                }
            }

            Section(header: Text(Localized.avatarHeader).foregroundColor(.gray)) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(RosterPlayer.emojiChoices, id: \.self) { emoji in
                        Button {
                            draft.emoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 20))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(draft.emoji == emoji ? Color.white.opacity(0.22) : Color.white.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color(white: 0.15))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.08).ignoresSafeArea())
        .navigationTitle(Localized.editPlayer)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localized.isItalian ? "Annulla" : "Cancel") { dismiss() }
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localized.isItalian ? "Salva" : "Save") {
                    if onSave(draft) {
                        dismiss()
                    } else {
                        showsDuplicateWarning = true
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
