import SwiftUI

struct OrderListItem: View {
    let order: OrderItem
    let onDelete: () -> Void
    let onEdit: () -> Void
    
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
        .background(Color(UIColor.systemBackground))
        .swipeActions(edge: .leading) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
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

// Preview with sample data
#Preview {
    List {
        OrderListItem(
            order: OrderItem(
                title: "Dinner at Restaurant A",
                dateTime: Date(),
                price: 150000,
                sideDishes: ["Rice", "Soup", "Salad"],
                verificationStatus: .verified
            ),
            onDelete: {},
            onEdit: {}
        )
        
        OrderListItem(
            order: OrderItem(
                title: "Lunch at Cafe B",
                dateTime: Date().addingTimeInterval(-86400),
                price: 85000,
                sideDishes: ["Fries", "Drink"],
                verificationStatus: .pending
            ),
            onDelete: {},
            onEdit: {}
        )
    }
    .listStyle(.plain)
}
