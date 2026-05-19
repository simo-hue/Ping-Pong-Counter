import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ScoreViewModel
    @Environment(\.dismiss) var dismiss
    
    let themesList = [
        ("Néon Classic", "Rosso & Blu", Color(red: 1.0, green: 0.25, blue: 0.35), Color(red: 0.0, green: 0.7, blue: 1.0)),
        ("Mint & Royal", "Verde & Viola", Color(red: 0.0, green: 0.85, blue: 0.55), Color(red: 0.55, green: 0.3, blue: 0.9)),
        ("Solar Flare", "Arancione & Teal", Color(red: 1.0, green: 0.55, blue: 0.0), Color(red: 0.0, green: 0.8, blue: 0.8))
    ]
    
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
                    Section(header: Text("Giocatori").foregroundColor(.gray)) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(themesList[viewModel.themeIndex].2)
                            TextField("Giocatore 1 (Sinistra)", text: $viewModel.p1Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(themesList[viewModel.themeIndex].3)
                            TextField("Giocatore 2 (Destra)", text: $viewModel.p2Name)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text("Regole Partita").foregroundColor(.gray)) {
                        Picker("Punti per Set", selection: $viewModel.targetScore) {
                            Text("11 Punti (Standard)").tag(11)
                            Text("21 Punti (Classico)").tag(21)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                        
                        Picker("Durata Match (Set)", selection: $viewModel.bestOfSets) {
                            Text("Set Singolo").tag(1)
                            Text("Al meglio di 3 set").tag(3)
                            Text("Al meglio di 5 set").tag(5)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                        
                        Toggle("Vantaggi (Vinci con 2 punti di scarto)", isOn: $viewModel.winByTwo)
                            .tint(themesList[viewModel.themeIndex].2)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                        
                        Picker("Rotazione Servizio", selection: $viewModel.serveRotationInterval) {
                            Text("Ogni 2 servizi").tag(2)
                            Text("Ogni 5 servizi").tag(5)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text("Audio & Voce").foregroundColor(.gray)) {
                        Toggle("Assistente Vocale (Sintesi Vocale)", isOn: $viewModel.isVoiceEnabled)
                            .tint(themesList[viewModel.themeIndex].2)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                    }
                    
                    Section(header: Text("Stile & Temi").foregroundColor(.gray)) {
                        Picker("Tema Grafico", selection: $viewModel.themeIndex) {
                            ForEach(0..<themesList.count, id: \.self) { idx in
                                Text(themesList[idx].0).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .listRowBackground(Color(white: 0.15))
                        
                        // Theme Preview Box
                        HStack(spacing: 20) {
                            Text("Anteprima Tema:")
                                .foregroundColor(.white)
                            Spacer()
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themesList[viewModel.themeIndex].2)
                                .frame(width: 40, height: 25)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themesList[viewModel.themeIndex].3)
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
                                Text("Resetta Partita")
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
