import SwiftUI

struct SettingsView: View {
    // Connect to the shared ViewModel to access the simulation toggle
    @EnvironmentObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Demonstration")) {
                    // This toggle directly controls the isFatigueSimulationActive
                    // property in our shared DashboardViewModel.
                    Toggle("Simulate Fatigue", isOn: $viewModel.isFatigueSimulationActive)
                    Text("When enabled, the next monitoring session will use simulated 'fatigued' ECG and EEG data patterns.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    // Provide a sample viewModel for the preview to work
    SettingsView()
        .environmentObject(DashboardViewModel())
        .preferredColorScheme(.dark)
}
