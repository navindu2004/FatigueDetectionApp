//
//  ContentView.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import SwiftUI

struct ContentView: View {
    // Create and observe the ViewModel. @StateObject ensures it's kept alive.
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        ZStack {
            // If showAlertView is true, we cover the whole screen with the alert.
            if viewModel.showAlertView {
                AlertView(viewModel: viewModel)
            } else {
                // Otherwise, show the main monitoring screen.
                MonitoringView(viewModel: viewModel)
            }
        }
        // This is where the watch will listen for messages from the iPhone.
        // We will set this up properly in a later step.
        .onAppear {
            // Example of how to test the alert view
            // DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            //     viewModel.didReceiveFatigueAlert()
            // }
        }
    }
}

// The main screen with the Start/Stop button.
struct MonitoringView: View {
    // @ObservedObject means this view is WATCHING the viewModel that was
    // created and owned by the ContentView.
    @ObservedObject var viewModel: WatchViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text(Date(), style: .time)
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            Button(action: {
                viewModel.toggleMonitoring()
            }) {
                // Change the button text and color based on the monitoring state.
                Text(viewModel.isMonitoringActive ? "Stop" : "Start")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .frame(width: 100, height: 100)
            .background(viewModel.isMonitoringActive ? Color.red : Color.green)
            .clipShape(Circle())
            .buttonStyle(PlainButtonStyle()) // Removes the default button background
            
            Text(viewModel.isMonitoringActive ? "Monitoring Active" : "Ready to Monitor")
                .foregroundColor(viewModel.isMonitoringActive ? .green : .secondary)
        }
    }
}


// --- Preview Provider ---
#Preview {
    ContentView()
}
