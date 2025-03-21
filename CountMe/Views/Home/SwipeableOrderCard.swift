import SwiftUI

struct SwipeableOrderCard: View {
    let order: OrderItem
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        ZStack {
            OrderCard(order: order)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete() // Now directly calls the deletion handler
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
