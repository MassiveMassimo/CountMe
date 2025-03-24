import SwiftUI
import SwiftData

@main
struct CountMeApp: App {
    var body: some Scene {
        WindowGroup {
            HomePage()
        }
        .modelContainer(AppSchema.container)
    }
}
