//
//  AlertView.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import SwiftUI

struct AlertView: View {
    // This view also observes the same ViewModel.
    @ObservedObject var viewModel: WatchViewModel
    
    var body: some View {
        ZStack {
            // Red background for the alert
            Color.red.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                
                Text("CRITICAL FATIGUE DETECTED")
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("Please pull over and rest now.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Button("Dismiss") {
                    // When dismissed, we tell the ViewModel to hide the alert
                    // and also stop the monitoring session.
                    viewModel.showAlertView = false
                    if viewModel.isMonitoringActive {
                        viewModel.toggleMonitoring()
                    }
                }
                .padding(.top, 8)
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.3))
            }
            .padding()
        }
    }
}
