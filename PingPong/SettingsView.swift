import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ScoreViewModel
    @Environment(\.dismiss) var dismiss
    
    let themesList = [
        ("Néon Classic", "Rosso & Blu", Color(red: 1.0, green: 0.25, blue: 0.35), Color(red: 0.0, green: 0.7, blue: 1.0)),
        ("Mint & Royal", "Verde & Viola", Color(red: 0.0, green: 0.85, blue: 0.55), Color(red: 0.55, green: 0.3, blue: 0.9)),
        ("Solar Flare", "Arancione & Teal", Color(red: 1.0, green: 0.55, blue: 0.0), Color(red: 0.0, green: 0.8, blue: 0.8))
    ]

    private var selectedThemeIndex: Int {
        themesList.indices.contains(viewModel.themeIndex) ? viewModel.themeIndex : 0
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
                                .foregroundColor(themesList[selectedThemeIndex].2)
                            TextField(Localized.p1Placeholder, text: $viewModel.p1Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(themesList[selectedThemeIndex].3)
                            TextField(Localized.p2Placeholder, text: $viewModel.p2Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text(Localized.rulesHeader).foregroundColor(.gray)) {
                        Picker(selection: $viewModel.targetScore) {
                            Text(Localized.points11).tag(11)
                            Text(Localized.points21).tag(21)
                        } label: {
                            Text(Localized.pointsPerSet)
                                .foregroundColor(.white)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                        
                        Picker(selection: $viewModel.bestOfSets) {
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
                        
                        Toggle(Localized.winByTwo, isOn: $viewModel.winByTwo)
                            .tint(themesList[selectedThemeIndex].2)
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
                            .tint(themesList[selectedThemeIndex].2)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text(Localized.styleHeader).foregroundColor(.gray)) {
                        Picker(selection: $viewModel.themeIndex) {
                            ForEach(0..<themesList.count, id: \.self) { idx in
                                Text(themesList[idx].0).tag(idx)
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
                                .fill(themesList[selectedThemeIndex].2)
                                .frame(width: 40, height: 25)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themesList[selectedThemeIndex].3)
                                .frame(width: 40, height: 25)
                        }
                        .listRowBackground(Color(white: 0.15))
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
            .preferredColorScheme(.dark)
        }
    }
}
