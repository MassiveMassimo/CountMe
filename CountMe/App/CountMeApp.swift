import SwiftUI
import SwiftData
import Foundation

@main
struct CountMeApp: App {
    var body: some Scene {
        WindowGroup {
            HomePage()
        }
        .modelContainer(AppSchema.container)
    }
}
