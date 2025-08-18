import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query(sort: \FatigueEvent.timestamp, order: .reverse) private var events: [FatigueEvent]
    @State private var selectedTimeFilter: TimeFilter = .all

    enum TimeFilter: String, CaseIterable {
        case last24h = "Last 24h"
        case last7d  = "Last 7 Days"
        case all     = "All Time"
    }

    private var filteredEvents: [FatigueEvent] {
        let now = Date()
        switch selectedTimeFilter {
        case .last24h:
            let start = now.addingTimeInterval(-24 * 3600)
            return events.filter { $0.timestamp >= start }
        case .last7d:
            let start = now.addingTimeInterval(-7 * 24 * 3600)
            return events.filter { $0.timestamp >= start }
        case .all:
            return events
        }
    }

    // Counts matching your two-state enum
    private var awakeEventsCount: Int {
        filteredEvents.filter { $0.state == .awake }.count
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
                    SummaryCardView(count: awakeEventsCount,    label: "Awake Events")
                    SummaryCardView(count: fatiguedAlertsCount, label: "Fatigued Alerts")
                }
                .padding()

                VStack(alignment: .leading) {
                    Text("Event Log")
                        .font(.headline)
                        .padding(.horizontal)

                    List(filteredEvents) { event in
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
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Reports")
            .navigationBarHidden(true)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

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
        .modelContainer(for: FatigueEvent.self, inMemory: true)
        .preferredColorScheme(.dark)
}
