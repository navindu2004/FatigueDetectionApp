//
//  FatigueDashboardView.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import SwiftUI
import Charts

struct FatigueDashboardView: View {
    // --- Connect to the Shared ViewModel ---
    // @EnvironmentObject tells this view to find the DashboardViewModel
    // that was placed into the environment by the FatigueDetectorApp.
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // --- Top Status Indicators ---
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
                    
                    // --- Current Fatigue Level ---
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT FATIGUE LEVEL")
                                .font(.caption).foregroundColor(.secondary)
                            HStack {
                                Circle()
                                    .fill(viewModel.fatigueLevel.displayColor)
                                    .frame(width: 10, height: 10)
                                Text(viewModel.fatigueLevel.displayText)
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundColor(viewModel.fatigueLevel.displayColor)
                            }
                        }
                    }
                    
                    // --- Charts and System Details ---
                    ChartCardView(
                        title: "ECG Data (from Watch)",
                        data: viewModel.ecgDataPoints,
                        lineColor: .red
                    )
                    
                    ChartCardView(
                        title: "Simulated EEG Data (from Wheel)",
                        data: viewModel.eegDataPoints,
                        lineColor: .blue
                    )
                    
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


// --- Reusable Sub-views (These remain the same) ---

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

struct ChartCardView: View {
    let title: String
    let data: [Double]
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
                    LineChartView(data: data, lineColor: lineColor)
                        .frame(height: 100)
                }
            }
        }
    }
}

struct LineChartView: View {
    let data: [Double]
    let lineColor: Color
    
    private var normalizedData: [CGFloat] {
        let maxVal = data.max() ?? 1.0
        let minVal = data.min() ?? 0.0
        let range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1.0
        return data.map { CGFloat(($0 - minVal) / range) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                for index in data.indices {
                    let xPosition = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let yPosition = (1 - normalizedData[index]) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: xPosition, y: yPosition))
                    } else {
                        path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                    }
                }
            }
            .stroke(lineColor, lineWidth: 2)
        }
    }
}

#Preview {
    // For the preview to work correctly with an @EnvironmentObject,
    // you must provide a sample instance for the preview to use.
    FatigueDashboardView()
        .environmentObject(DashboardViewModel())
        .preferredColorScheme(.dark)
}
