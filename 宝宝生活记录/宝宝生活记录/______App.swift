import SwiftUI
import SwiftData

@main
struct ______App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        _ = await NotificationManager.shared.requestPermission()
                    }
                }
        }
        .modelContainer(for: [RecordModel.self, BabyProfile.self])
    }
}
