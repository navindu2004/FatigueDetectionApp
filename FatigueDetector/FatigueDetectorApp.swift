//
//  FatigueDetectorApp.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import SwiftUI

@main
struct FatigueDetectorApp: App {
    // Create a single, shared instance of the DashboardViewModel.
    // @StateObject ensures it stays alive for the entire lifecycle of the app.
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Make the shared ViewModel available to all sub-views.
                .environmentObject(dashboardViewModel)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            FatigueDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(.dark)
    }
}
