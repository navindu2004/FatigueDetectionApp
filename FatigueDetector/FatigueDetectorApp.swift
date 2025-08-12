//
//  FatigueDetectorApp.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import SwiftUI

@main
struct FatigueDetectorApp: App {
    var body: some Scene {
        WindowGroup {
            // This is the root view of our application
            MainTabView()
        }
    }
}


// We will create a new file for this view next
struct MainTabView: View {
    var body: some View {
        TabView {
            // --- Dashboard Tab ---
            FatigueDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }

            // --- Reports Tab ---
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }

            // --- Settings Tab ---
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        // Apply a dark color scheme to match your mockups
        .preferredColorScheme(.dark)
    }
}
