import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("Settings will be available here.")
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
