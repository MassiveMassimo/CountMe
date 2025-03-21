import Foundation

enum OrderFilter: String, CaseIterable {
    case all = "All"
    case verified = "Verified"
    case pending = "Pending"

    var title: String {
        return self.rawValue
    }
}
