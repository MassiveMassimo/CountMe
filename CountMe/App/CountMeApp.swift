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
    func checkInfoPlistCameraDescription() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) {
            print("Camera Usage Description:")
            print(dict["NSCameraUsageDescription"] ?? "NO DESCRIPTION FOUND")
        } else {
            print("Could not read Info.plist")
        }
    }
}
