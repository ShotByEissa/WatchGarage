import SwiftUI

@main
struct WatchGarageApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
