import SwiftUI

@main
struct MinimalLooperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
} 