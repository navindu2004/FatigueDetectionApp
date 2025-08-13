//
//  FatigueDetectorWatchAppApp.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import SwiftUI

@main
struct FatigueDetectorWatchApp_Watch_AppApp: App {
    // Create the shared ViewModel for the whole watch app
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Pass the ViewModel into the environment for all sub-views to access
                .environmentObject(viewModel)
        }
    }
}
