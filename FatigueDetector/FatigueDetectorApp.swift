import SwiftUI
import SwiftData

@main
struct FatigueDetectorApp: App {
    @StateObject private var dashboardViewModel = DashboardViewModel()

    // SwiftData container (unchanged)
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

    // 👇 Configure the Pre‑Drive service with your backend base URL (Option A)
    private let preDriveService = PreDriveService(
        baseURL: URL(string: PreDriveConfig.baseURL)!
    )

    var body: some View {
        TabView {
            // Dashboard (unchanged)
            FatigueDashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }

            // NEW: Pre‑Drive tab
            NavigationStack {
                PreDriveView(service: preDriveService)
            }
            .tabItem { Label("Pre-Drive", systemImage: "steeringwheel") }

            // Reports (unchanged)
            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.text.fill") }

            // Settings (unchanged)
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
