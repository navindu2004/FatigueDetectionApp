import SwiftUI

struct SettingsView: View {
    // We create an instance of the manager to use here.
    private let ecgManager = ECGHealthKitManager()
    @State private var authorizationStatus = "Unknown"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Permissions")) {
                    Button("Request HealthKit ECG Permission") {
                        requestPermission()
                    }
                    Text("Status: \(authorizationStatus)")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func requestPermission() {
        print("Requesting HealthKit permission from iPhone app...")
        ecgManager.requestAuthorization { success in
            if success {
                print("✅ HealthKit permission granted via iPhone.")
                self.authorizationStatus = "Granted"
            } else {
                print("❌ HealthKit permission denied via iPhone.")
                self.authorizationStatus = "Denied"
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
