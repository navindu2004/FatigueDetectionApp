import SwiftUI

struct ContentView: View {
    @StateObject var ecgManager = ECGManager()
    
    var body: some View {
        VStack {
            Text("Latest ECG:")
                .font(.headline)
            Text(ecgManager.latestClassification)
                .foregroundColor(.blue)
            Button("Refresh ECG") {
                ecgManager.fetchLatestECG()
            }
        }
    }
}
