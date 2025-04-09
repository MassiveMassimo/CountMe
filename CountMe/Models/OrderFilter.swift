import Foundation

enum OrderFilter: String, CaseIterable {
    case all = "All"
    case verified = "Verified"
    case pending = "Pending"
    case mismatch = "Mismatch"

    var title: String {
        return self.rawValue
    }
}
