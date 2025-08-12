import SwiftUI

struct ReportsView: View {
    var body: some View {
        NavigationView {
            Text("Reports will be shown here.")
                .navigationTitle("Reports")
        }
    }
}

#Preview {
    ReportsView()
        .preferredColorScheme(.dark)
}
