import SwiftUI

struct SettingsView: View {
    // Existing shared VM (unchanged)
    @EnvironmentObject var viewModel: DashboardViewModel

    // Profile + health fields
    @State private var name: String = ""
    @State private var ageText: String = ""
    @State private var heightText: String = ""   // cm
    @State private var weightText: String = ""   // kg

    @State private var saveMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Greeting card that updates when 'name' changes
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome\(name.isEmpty ? "" : ", \(name)")!")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Enter your details in \"Update Health Metrics\" for a more personalized pre‑drive analysis and insights.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // --- Existing section (left intact) ---
                Section(header: Text("Demonstration")) {
                    Toggle("Simulate Fatigue", isOn: $viewModel.isFatigueSimulationActive)
                    Text("When enabled, the next monitoring session will use simulated 'fatigued' ECG and EEG data patterns.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // --- New: Personal Health Metrics (used by Pre‑Drive) ---
                Section(header: Text("Update Health Metrics")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("e.g., Alex", text: $name)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                            .autocorrectionDisabled(true)
                    }

                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("e.g., 35", text: $ageText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                    }

                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("e.g., 180", text: $heightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                    }

                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("e.g., 75", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                    }

                    Button(action: saveHealthData) {
                        HStack {
                            Spacer()
                            Text("Save Health Data")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear(perform: loadFromDefaults)
    }

    // MARK: - Persistence
    private func loadFromDefaults() {
        let d = UserDefaults.standard

        name = d.string(forKey: "profile.name") ?? ""

        if let age = d.object(forKey: "health.age") as? Int {
            ageText = String(age)
        } else {
            ageText = ""
        }

        if let h = d.object(forKey: "health.height") as? Double {
            heightText = String(h)
        } else {
            heightText = ""
        }

        if let w = d.object(forKey: "health.weight") as? Double {
            weightText = String(w)
        } else {
            weightText = ""
        }
    }

    private func saveHealthData() {
        let d = UserDefaults.standard

        // Name
        d.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile.name")

        // Age
        if let age = Int(ageText.trimmingCharacters(in: .whitespaces)) {
            d.set(age, forKey: "health.age")
        } else {
            d.removeObject(forKey: "health.age")
        }

        // Height (cm)
        if let height = Double(heightText.trimmingCharacters(in: .whitespaces)) {
            d.set(height, forKey: "health.height")
        } else {
            d.removeObject(forKey: "health.height")
        }

        // Weight (kg)
        if let weight = Double(weightText.trimmingCharacters(in: .whitespaces)) {
            d.set(weight, forKey: "health.weight")
        } else {
            d.removeObject(forKey: "health.weight")
        }

        withAnimation { saveMessage = "✓ Saved!" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { saveMessage = "" }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DashboardViewModel())
        .preferredColorScheme(.dark)
}
