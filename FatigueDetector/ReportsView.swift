import SwiftUI
import SwiftData

struct ReportsView: View {
    // This allows the view to perform delete actions on the database.
    @Environment(\.modelContext) private var modelContext
    
    // This automatically fetches and sorts all saved FatigueEvent objects.
    @Query(sort: \FatigueEvent.timestamp, order: .reverse) private var events: [FatigueEvent]
    
    // State for the UI
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var showClearAlert = false // To control the confirmation alert
    
    // Enum for the picker
    enum TimeFilter: String, CaseIterable {
        case last24h = "Last 24h"
        case last7d  = "Last 7 Days"
        case all     = "All Time"
    }
    
    // This computed property filters the events based on the picker's selection.
    private var filteredEvents: [FatigueEvent] {
        let now = Date()
        switch selectedTimeFilter {
        case .last24h:
            let startTime = now.addingTimeInterval(-24 * 3600)
            return events.filter { $0.timestamp >= startTime }
        case .last7d:
            let startTime = now.addingTimeInterval(-7 * 24 * 3600)
            return events.filter { $0.timestamp >= startTime }
        case .all:
            return events
        }
    }


    private var fatiguedAlertsCount: Int {
        filteredEvents.filter { $0.state == .fatigued }.count
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Fatigue Reports")
                    .font(.title2).fontWeight(.semibold)
                    .padding(.top)

                Picker("Time Filter", selection: $selectedTimeFilter) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack(spacing: 16) {
                    // Update the summary card labels to match the new drowsy/fatigued logic
                    SummaryCardView(count: fatiguedAlertsCount, label: "Fatigued Alerts")
                }
                .padding()

                VStack(alignment: .leading) {
                    Text("Event Log")
                        .font(.headline)
                        .padding(.horizontal)

                    List {
                        // Display the filtered events
                        ForEach(filteredEvents) { event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.state.displayText)
                                        .fontWeight(.bold)
                                        .foregroundColor(event.state.displayColor)
                                    Text(event.timestamp, style: .date)
                                }
                                Spacer()
                                Text(event.timestamp, style: .time)
                            }
                            .listRowBackground(Color(.secondarySystemBackground))
                        }
                        
                        // --- "Clear History" Button Section ---
                        // This section will only appear if there is at least one event to delete.
                        if !events.isEmpty {
                            Section {
                                Button(role: .destructive) {
                                    // This button doesn't delete directly; it shows the confirmation alert.
                                    showClearAlert = true
                                } label: {
                                    Label("Clear History", systemImage: "trash")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .listRowBackground(Color(.secondarySystemBackground))
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Reports")
            .navigationBarHidden(true)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            // This modifier presents the confirmation alert when `showClearAlert` is true.
            .alert("Clear All Reports?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    // If the user confirms, this action calls the delete function.
                    clearAllEvents()
                }
                Button("Cancel", role: .cancel) { } // A standard cancel button.
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    /// Deletes all FatigueEvent objects from the SwiftData database.
    private func clearAllEvents() {
        print("Clearing all \(events.count) fatigue events from the database.")
        do {
            // This is the most efficient way to delete all objects of a certain type.
            try modelContext.delete(model: FatigueEvent.self)
        } catch {
            print("Failed to clear event history: \(error)")
        }
    }
}

// Reusable view for the summary cards
struct SummaryCardView: View {
    let count: Int
    let label: String

    var body: some View {
        VStack {
            Text("\(count)")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


#Preview {
    ReportsView()
        // We need to provide a sample database container for the preview to work.
        .modelContainer(for: FatigueEvent.self, inMemory: true)
        .preferredColorScheme(.dark)
}
