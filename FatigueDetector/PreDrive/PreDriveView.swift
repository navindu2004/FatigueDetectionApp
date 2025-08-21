import SwiftUI
import SwiftData   // <-- we need this to pass ModelContext to the VM

// MARK: - Small badge for the risk level
private struct RiskBadge: View {
    let level: RiskAssessment.Level
    var body: some View {
        Text(level.rawValue)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill({
                    switch level {
                    case .low:       return Color.green.opacity(0.85)
                    case .moderate:  return Color.yellow.opacity(0.85)
                    case .high:      return Color.red.opacity(0.85)
                    }
                }())
            )
            .foregroundStyle(level == .moderate ? .black : .white)
    }
}

struct PreDriveView: View {
    // Needed to fetch SwiftData history in the VM
    @Environment(\.modelContext) private var modelContext

    // Pull current fatigue state from your existing dashboard VM
    @EnvironmentObject private var dashboard: DashboardViewModel

    @StateObject private var vm: PreDriveViewModel

    // Focus management for keyboard
    private enum Field { case sleep, duration }
    @FocusState private var focusedField: Field?

    init(service: PreDriveServicing) {
        _vm = StateObject(wrappedValue: PreDriveViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Card: PRE-DRIVE FATIGUE CHECK
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRE-DRIVE FATIGUE CHECK")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Enter details about your upcoming trip to get a personalized fatigue risk assessment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        row(label: "Hours Slept Last Night") {
                            TextField("e.g., 7.5", text: $vm.sleep)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .sleep)
                                .submitLabel(.done)
                        }

                        row(label: "Planned Trip Duration (hrs)") {
                            TextField("e.g., 3", text: $vm.duration)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .duration)
                                .submitLabel(.done)
                        }

                        row(label: "Time of Day") {
                            Picker("Time of Day", selection: $vm.timeOfDay) {
                                Text("Morning").tag("Morning")
                                Text("Afternoon").tag("Afternoon")
                                Text("Evening").tag("Evening")
                                Text("Night").tag("Night")
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Button {
                        // close keyboard first for a smooth feel
                        focusedField = nil

                        Task {
                            // Build a robust current state string from the DashboardViewModel
                            let currentStateString: String = {
                                switch dashboard.fatigueLevel {
                                case .awake:   return "Awake"
                                case .fatigued:return "Fatigued"
                                }
                            }()

                            await vm.analyze(
                                modelContext: modelContext,               // from @Environment(\.modelContext)
                                currentState: currentStateString
                            )
                        }
                    } label: {
                        Text(vm.isLoading ? "Analyzing..." : "Analyze Risk")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)
                    .padding(.top, 4)
 
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))

                // Card: Result
                if let a = vm.assessment {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("RISK LEVEL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            RiskBadge(level: a.riskLevel)
                        }

                        Divider()

                        Text("EXPLANATION")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(a.explanation)
                            .font(.body)

                        if !a.recommendations.isEmpty {
                            Divider()
                            Text("RECOMMENDATIONS")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(a.recommendations, id: \.self) { rec in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("✓").foregroundStyle(.blue)
                                        Text(rec)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                }

                if let err = vm.error {
                    Text(err)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .contentShape(Rectangle())     // so taps on empty areas register
        .onTapGesture { focusedField = nil } // tap anywhere to hide
        .navigationTitle("Pre-Drive Check")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .scrollDismissesKeyboard(.interactively) // drag to hide (iOS 16+)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 16)
            content().frame(width: 140)
        }
    }
}
