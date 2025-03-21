import SwiftUI

extension View {
    /// Adds an empty state overlay when a collection is empty
    func emptyStateOverlay(isEmpty: Bool, onAddAction: @escaping () -> Void) -> some View {
        self.overlay {
            if isEmpty {
                EmptyStateView(onAddReceipt: onAddAction)
            }
        }
    }
}
