import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ScoreViewModel

    // Points-per-set and match length are staged rather than applied live: every intermediate
    // value of a stepper would otherwise reset — and archive — the match in progress.
    @State private var draftTargetScore: Int
    @State private var draftBestOfSets: Int
    @State private var isShowingApplyConfirmation = false

    init(viewModel: ScoreViewModel) {
        self.viewModel = viewModel
        _draftTargetScore = State(initialValue: viewModel.targetScore)
        _draftBestOfSets = State(initialValue: viewModel.bestOfSets)
    }

    private var hasPendingRuleChanges: Bool {
        draftTargetScore != viewModel.targetScore || draftBestOfSets != viewModel.bestOfSets
    }

    private let supportURL = URL(string: "https://simo-hue.github.io/Ping-Pong-Counter/#support")
    private let privacyPolicyURL = URL(string: "https://simo-hue.github.io/Ping-Pong-Counter/#privacy")

    private var selectedTheme: AppTheme {
        AppTheme.theme(at: viewModel.themeIndex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark gradient
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section(header: Text(Localized.playersHeader).foregroundColor(.gray)) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(selectedTheme.p1Color)
                            TextField(Localized.p1Placeholder, text: $viewModel.p1Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(selectedTheme.p2Color)
                            TextField(Localized.p2Placeholder, text: $viewModel.p2Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section {
                        Stepper(value: $draftTargetScore, in: ScoreViewModel.validTargetScoreRange) {
                            HStack {
                                Text(Localized.pointsPerSet)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(draftTargetScore)")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(selectedTheme.p1Color)
                            }
                        }
                        .listRowBackground(Color(white: 0.15))

                        HStack(spacing: 10) {
                            quickTargetButton(11, label: Localized.points11)
                            quickTargetButton(21, label: Localized.points21)
                        }
                        .listRowBackground(Color(white: 0.15))

                        Picker(selection: $draftBestOfSets) {
                            Text(Localized.singleSet).tag(1)
                            Text(Localized.bestOf3).tag(3)
                            Text(Localized.bestOf5).tag(5)
                        } label: {
                            Text(Localized.matchDuration)
                                .foregroundColor(.white)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))

                        if hasPendingRuleChanges {
                            Button {
                                if viewModel.hasMeaningfulMatchState {
                                    isShowingApplyConfirmation = true
                                } else {
                                    commitRuleChanges()
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(Localized.applyNewRules)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundColor(selectedTheme.p1Color)
                            }
                            .listRowBackground(Color(white: 0.15))
                        }
                    } header: {
                        Text(Localized.rulesHeader).foregroundColor(.gray)
                    } footer: {
                        Text(Localized.pendingRulesFooter)
                            .foregroundColor(.gray)
                    }

                    Section(header: Text(Localized.serveRulesHeader).foregroundColor(.gray)) {
                        Toggle(Localized.winByTwo, isOn: $viewModel.winByTwo)
                            .tint(selectedTheme.p1Color)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))

                        Picker(selection: $viewModel.serveRotationInterval) {
                            Text(Localized.every2Serves).tag(2)
                            Text(Localized.every5Serves).tag(5)
                        } label: {
                            Text(Localized.serviceRotation)
                                .foregroundColor(.white)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text(Localized.audioHeader).foregroundColor(.gray)) {
                        Toggle(Localized.voiceAssistant, isOn: $viewModel.isVoiceEnabled)
                            .tint(selectedTheme.p1Color)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))

                        Toggle(Localized.soundEffects, isOn: $viewModel.isSoundEnabled)
                            .tint(selectedTheme.p1Color)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))

                        Picker(selection: $viewModel.hapticIntensity) {
                            Text(Localized.hapticsOff).tag(HapticIntensity.off)
                            Text(Localized.hapticsLight).tag(HapticIntensity.light)
                            Text(Localized.hapticsFull).tag(HapticIntensity.full)
                        } label: {
                            Text(Localized.hapticsLabel)
                                .foregroundColor(.white)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                    }

                    Section {
                        Toggle(Localized.keepScreenAwake, isOn: $viewModel.keepScreenAwake)
                            .tint(selectedTheme.p1Color)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))

                        Toggle(Localized.showMatchTimer, isOn: $viewModel.showMatchTimer)
                            .tint(selectedTheme.p1Color)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                    } header: {
                        Text(Localized.displayHeader).foregroundColor(.gray)
                    } footer: {
                        Text(Localized.keepScreenAwakeFooter).foregroundColor(.gray)
                    }


                    Section(header: Text(Localized.styleHeader).foregroundColor(.gray)) {
                        Picker(selection: $viewModel.themeIndex) {
                            ForEach(AppTheme.all) { theme in
                                Text("\(theme.name) — \(theme.subtitle)").tag(theme.id)
                            }
                        } label: {
                            Text(Localized.graphicTheme)
                                .foregroundColor(.white)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                        
                        // Theme Preview Box
                        HStack(spacing: 20) {
                            Text(Localized.themePreview)
                                .foregroundColor(.white)
                            Spacer()
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTheme.p1Color)
                                .frame(width: 40, height: 25)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTheme.p2Color)
                                .frame(width: 40, height: 25)
                        }
                        .listRowBackground(Color(white: 0.15))
                    }

                    Section(header: Text(Localized.appInfoHeader).foregroundColor(.gray)) {
                        if let supportURL {
                            Link(destination: supportURL) {
                                Label(Localized.supportLink, systemImage: "questionmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(white: 0.15))
                        }

                        if let privacyPolicyURL {
                            Link(destination: privacyPolicyURL) {
                                Label(Localized.privacyPolicy, systemImage: "lock.shield.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(white: 0.15))
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            viewModel.resetMatch()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text(Localized.resetMatch)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Localized.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localized.closeButton) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                Localized.applyRulesConfirmTitle,
                isPresented: $isShowingApplyConfirmation,
                titleVisibility: .visible
            ) {
                Button(Localized.applyNewRules, role: .destructive) {
                    commitRuleChanges()
                }
                Button(Localized.isItalian ? "Annulla" : "Cancel", role: .cancel) {}
            } message: {
                Text(Localized.applyRulesConfirmMessage)
            }
            // Re-seed the drafts if the rules change from elsewhere (e.g. a reset) while open.
            .onChange(of: viewModel.targetScore) { _, newValue in
                draftTargetScore = newValue
            }
            .onChange(of: viewModel.bestOfSets) { _, newValue in
                draftBestOfSets = newValue
            }
            .preferredColorScheme(.dark)
        }
    }

    private func quickTargetButton(_ value: Int, label: String) -> some View {
        let isSelected = draftTargetScore == value

        return Button {
            draftTargetScore = value
        } label: {
            Text(label)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                .background(
                    Capsule().fill(isSelected ? selectedTheme.p1Color : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private func commitRuleChanges() {
        viewModel.applyRules(targetScore: draftTargetScore, bestOfSets: draftBestOfSets)
    }
}
