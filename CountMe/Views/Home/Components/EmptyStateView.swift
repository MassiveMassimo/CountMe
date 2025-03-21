import SwiftUI

struct EmptyStateView: View {
    let onAddReceipt: () -> Void
    
    var body: some View {
        ContentUnavailableView(
            label: {
                Label("No Orders", systemImage: "doc.text.magnifyingglass")
            },
            description: {
                Text("Add orders by tapping the + button")
            },
            actions: {
                Button(action: onAddReceipt) {
                    Text("Add Receipt")
                }
                .buttonStyle(.bordered)
            }
        )
    }
}
