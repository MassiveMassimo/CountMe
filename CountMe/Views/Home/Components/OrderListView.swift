import SwiftUI

struct OrderListView: View {
    let orders: [OrderItem]
    let onDelete: (OrderItem) -> Void
    let onEdit: (OrderItem) -> Void
    
    var body: some View {
        List {
            ForEach(orders) { order in
                SwipeableOrderCard(
                    order: order,
                    onDelete: { onDelete(order) },
                    onEdit: { onEdit(order) }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .background(Color.grayBackground)
    }
}
