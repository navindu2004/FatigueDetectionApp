import SwiftUI
import SwiftData

@main
struct FatigueDetectorApp: App {
    @StateObject private var dashboardViewModel = DashboardViewModel()

    // SwiftData container (no custom URL on this SDK)
    private let modelContainer: ModelContainer = {
        let schema = Schema([FatigueEvent.self])

        // Ensure the Application Support directory exists
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            do {
                try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            } catch {
                print("⚠️ Failed to create Application Support directory: \(error)")
            }
        }

        // Use the initializer supported by your SDK
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dashboardViewModel)
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Root Tabs

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: DashboardViewModel

    var body: some View {
        TabView {
            FatigueDashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.text.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Let the VM persist events
            viewModel.modelContext = modelContext
        }
    }
}
