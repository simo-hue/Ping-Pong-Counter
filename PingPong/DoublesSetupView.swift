import SwiftUI

/// Configures a doubles match: the four player names and who opens the serving rotation.
struct DoublesSetupView: View {
    @ObservedObject var viewModel: ScoreViewModel

    private var theme: AppTheme { AppTheme.theme(at: viewModel.themeIndex) }
    private var lineup: DoublesLineup { viewModel.doublesLineup }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Form {
                teamSection(.player1, title: Localized.teamOneLabel, color: theme.p1Color, teamName: $viewModel.p1Name)
                teamSection(.player2, title: Localized.teamTwoLabel, color: theme.p2Color, teamName: $viewModel.p2Name)
                rotationSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Localized.doublesMode)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func teamSection(_ team: Player, title: String, color: Color, teamName: Binding<String>) -> some View {
        Section {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(color)
                TextField(title, text: teamName)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color(white: 0.15))

            seatField(DoublesSeat(team: team, slot: .first), color: color)
            seatField(DoublesSeat(team: team, slot: .second), color: color)

            Button {
                viewModel.swapDoublesPartners(on: team)
            } label: {
                Label(Localized.swapPartnersLabel, systemImage: "arrow.up.arrow.down")
                    .foregroundColor(color)
            }
            .listRowBackground(Color(white: 0.15))
        } header: {
            Text(title).foregroundColor(.gray)
        }
    }

    private func seatField(_ seat: DoublesSeat, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 8, height: 8)

            TextField(
                Localized.newPlayerPlaceholder,
                text: Binding(
                    get: { lineup.name(for: seat) },
                    set: { newValue in
                        var updated = viewModel.doublesLineup
                        updated.setName(newValue, for: seat)
                        viewModel.updateDoublesLineup(updated)
                    }
                )
            )
            .foregroundColor(.white)

            if !viewModel.roster.isEmpty {
                Menu {
                    ForEach(viewModel.roster) { player in
                        Button("\(player.emoji)  \(player.name)") {
                            var updated = viewModel.doublesLineup
                            updated.setName(player.name, for: seat)
                            viewModel.updateDoublesLineup(updated)
                        }
                    }
                } label: {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(color)
                }
                .accessibilityLabel(Localized.chooseFromRoster)
            }
        }
        .listRowBackground(Color(white: 0.15))
    }

    private var rotationSection: some View {
        Section {
            Picker(selection: openingServerBinding) {
                ForEach(DoublesSeat.all) { seat in
                    Text(lineup.name(for: seat)).tag(seat)
                }
            } label: {
                Text(Localized.firstServerLabel).foregroundColor(.white)
            }
            .pickerStyle(.menu)
            .tint(.white)
            .listRowBackground(Color(white: 0.15))

            // Only the opposing team can receive, so the choice is between two seats.
            Picker(selection: openingReceiverBinding) {
                ForEach(DoublesSeat.all.filter { $0.team == lineup.setStartingServer.team.opponent }) { seat in
                    Text(lineup.name(for: seat)).tag(seat)
                }
            } label: {
                Text(Localized.firstReceiverLabel).foregroundColor(.white)
            }
            .pickerStyle(.menu)
            .tint(.white)
            .listRowBackground(Color(white: 0.15))

            rotationPreview
                .listRowBackground(Color(white: 0.15))
        } header: {
            Text(Localized.openingRotationHeader).foregroundColor(.gray)
        } footer: {
            Text(Localized.doublesFooter).foregroundColor(.gray)
        }
    }

    /// Shows the whole cycle, so the players can see the order before the match starts.
    private var rotationPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lineup.serveCycle.enumerated()), id: \.offset) { index, seat in
                let receiver = lineup.serveCycle[(index + 1) % lineup.serveCycle.count]

                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(width: 14)

                    Text(Localized.servesToDescription(
                        server: lineup.name(for: seat),
                        receiver: lineup.name(for: receiver)
                    ))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var openingServerBinding: Binding<DoublesSeat> {
        Binding(
            get: { lineup.setStartingServer },
            set: { seat in
                var updated = viewModel.doublesLineup
                // Keep the existing receiver when it is still legal; otherwise the lineup's own
                // validation drops it to the opposing team's first slot.
                updated.setOpening(server: seat, receiver: lineup.setStartingReceiver)
                viewModel.updateDoublesLineup(updated)
            }
        )
    }

    private var openingReceiverBinding: Binding<DoublesSeat> {
        Binding(
            get: { lineup.setStartingReceiver },
            set: { seat in
                var updated = viewModel.doublesLineup
                updated.setOpening(server: lineup.setStartingServer, receiver: seat)
                viewModel.updateDoublesLineup(updated)
            }
        )
    }
}
