//
//  ContentView.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import SwiftUI

struct ContentView: View {
    // Get the shared ViewModel from the environment
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        ZStack {
            if viewModel.showAlertView {
                // The AlertView will also get the ViewModel from the environment
                AlertView()
            } else {
                // The MonitoringView will also get the ViewModel from the environment
                MonitoringView()
            }
        }
    }
}

struct MonitoringView: View {
    // Get the shared ViewModel from the environment
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text(Date(), style: .time)
                .font(.largeTitle).fontWeight(.semibold)
            
            Button(action: {
                viewModel.toggleMonitoring()
            }) {
                Text(viewModel.isMonitoringActive ? "Stop" : "Start")
                    .font(.title2).fontWeight(.bold).foregroundColor(.black)
            }
            .frame(width: 100, height: 100)
            .background(viewModel.isMonitoringActive ? Color.red : Color.green)
            .clipShape(Circle())
            .buttonStyle(PlainButtonStyle())
            
            Text(viewModel.isMonitoringActive ? "Monitoring Active" : "Ready to Monitor")
                .foregroundColor(viewModel.isMonitoringActive ? .green : .secondary)
        }
    }
}

#Preview {
    // For the preview to work, we need to provide a sample ViewModel
    ContentView()
        .environmentObject(WatchViewModel())
}
