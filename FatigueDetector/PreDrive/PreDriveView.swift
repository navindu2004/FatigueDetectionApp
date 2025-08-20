// FatigueDetector/FatigueDetector/PreDrive/PreDriveView.swift
import SwiftUI

private struct RiskBadge: View {
    let level: RiskAssessment.Level
    var body: some View {
        Text(level.rawValue)
            .fontWeight(.semibold)
            .padding(.horizontal, 12).padding(.vertical, 6)
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
    @StateObject private var vm: PreDriveViewModel

    init(service: PreDriveServicing) {
        _vm = StateObject(wrappedValue: PreDriveViewModel(service: service))
    }

    // If you keep health/history in Settings/Reports, you can pass summaries in
    private var healthSummary: (Int?, Int?, Int?) { (nil, nil, nil) }
    private var historySummary: (Int?, Int?) { (nil, nil) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Card: PRE-DRIVE FATIGUE CHECK
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRE-DRIVE FATIGUE CHECK")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Enter details about your upcoming trip to get a personalized fatigue risk assessment.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        row(label: "Hours Slept Last Night") {
                            TextField("e.g., 7.5", text: $vm.sleep)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                        }
                        row(label: "Planned Trip Duration (hrs)") {
                            TextField("e.g., 3", text: $vm.duration)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
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
                        Task {
                            await vm.analyze(
                                health: (healthSummary.0, healthSummary.1, healthSummary.2),
                                history: (historySummary.0, historySummary.1)
                            )
                        }
                    } label: {
                        Text(vm.isLoading ? "Analyzing..." : "Analyze Risk")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)
                    .padding(.top, 4)
                }
                .padding().background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))

                // Card: Result
                if let a = vm.assessment {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("RISK LEVEL").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            RiskBadge(level: a.riskLevel)
                        }
                        Divider()
                        Text("EXPLANATION").font(.caption).foregroundStyle(.secondary)
                        Text(a.explanation)

                        if !a.recommendations.isEmpty {
                            Divider()
                            Text("RECOMMENDATIONS").font(.caption).foregroundStyle(.secondary)
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
                    .padding().background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                }

                if let err = vm.error {
                    Text(err).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Pre-Drive Check")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 16)
            content().frame(width: 140)
        }
    }
}
