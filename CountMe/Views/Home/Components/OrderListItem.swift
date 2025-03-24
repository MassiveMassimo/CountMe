import SwiftUI

struct OrderListItem: View {
    let order: OrderItem
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onScanProof: () -> Void
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with title and status
            HStack {
                Text(order.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                StatusBadge(status: order.verificationStatus)
            }
            
            // Date and price
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    
                    Text(order.dateTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                .frame(width: 16)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    
                    Text(order.dateTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                Text(currencyFormatter.string(from: NSNumber(value: order.price)) ?? "Rp0")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
            }
            
            // Side dishes chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(order.sideDishes, id: \.self) { dish in
                        Text(dish)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.systemGray5))
                            .foregroundStyle(Color.secondary)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .swipeActions(edge: .leading) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            
            // Only show scan proof button for pending items
            if order.verificationStatus == .pending {
                Button {
                    onScanProof()
                } label: {
                    Label("Scan Proof", systemImage: "doc.text.viewfinder")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// Preview for SwiftData
#Preview {
    let container = AppSchema.previewContainer
    let order = OrderItem.sampleOrders[0]
    
    return OrderListItem(
        order: order,
        onDelete: {},
        onEdit: {},
        onScanProof: {}
    )
    .modelContainer(container)
}
