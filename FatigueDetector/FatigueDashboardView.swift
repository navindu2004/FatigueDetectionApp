import SwiftUI
import Charts

// This struct defines the data points for our new charts.
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// This is the main view for the first tab.
struct FatigueDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Status Indicators
                    HStack(spacing: 16) {
                        StatusIndicatorView(
                            title: "WATCH CONNECTION",
                            statusText: viewModel.isWatchConnected ? "Connected" : "Disconnected",
                            statusColor: viewModel.isWatchConnected ? .green : .red
                        )
                        
                        StatusIndicatorView(
                            title: "MONITORING STATUS",
                            statusText: viewModel.isMonitoringActive ? "Active" : "Inactive",
                            statusColor: viewModel.isMonitoringActive ? .green : .gray
                        )
                    }
                    
                    // Current Fatigue Level
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT FATIGUE LEVEL")
                                .font(.caption).foregroundColor(.secondary)
                            HStack {
                                Circle()
                                    .fill(viewModel.fatigueTrafficColor)   // <— changed
                                    .frame(width: 10, height: 10)
                                Text(viewModel.fatigueLevel.displayText)
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundColor(viewModel.fatigueTrafficColor) // <— changed
                            }
                        }
                    }
                    
                    // ECG Data Chart
                    ModernChartCardView(
                        title: "ECG Data (from Watch)",
                        data: viewModel.ecgChartData,
                        lineColor: .red
                    )
                    
                    // EEG Data Chart
                    ModernChartCardView(
                        title: "Simulated EEG Data (from Wheel)",
                        data: viewModel.eegChartData,
                        lineColor: .blue
                    )
                    
                    // System Details
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SYSTEM DETAILS").font(.caption).foregroundColor(.secondary)
                            Text("An XGBoost model analyzes ECG (Watch) and EEG (Steering Wheel) data to calculate a fatigue score and determine the driver's state.")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Fatigue Detection")
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

// --- ALL REUSABLE SUB-VIEWS ARE DEFINED BELOW ---

// A reusable view for the card-like containers.
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        HStack {
            content
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// A reusable view for the top status indicators.
struct StatusIndicatorView: View {
    let title: String
    let statusText: String
    let statusColor: Color
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusText)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// A reusable view for the modern chart cards.
struct ModernChartCardView: View {
    let title: String
    let data: [ChartDataPoint]
    let lineColor: Color

    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if data.isEmpty {
                    Text("Ready to Monitor")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                } else {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(lineColor)
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.hour().minute().second())
                        }
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 100)
                }
            }
        }
    }
}

// --- Preview Provider ---
#Preview {
    // We need to provide a sample ViewModel for the preview to work.
    FatigueDashboardView()
        .environmentObject(DashboardViewModel())
        .preferredColorScheme(.dark)
}
