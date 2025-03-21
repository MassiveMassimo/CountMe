import SwiftUI

struct OrderCard: View {
    let order: OrderItem
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and status
            HStack {
                Text(order.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.grayText)
                
                Spacer()
                
                StatusBadge(status: order.verificationStatus)
            }
            
            // Date and price
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.grayTextSecondary)
                    
                    Text(order.dateTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.grayTextSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(Color.grayTextSecondary)
                    
                    Text(order.dateTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.grayTextSecondary)
                }
                
                Spacer()
                
                Text(currencyFormatter.string(from: NSNumber(value: order.price)) ?? "Rp0")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.grayText)
            }
            
            // Divider
            Divider()
                .background(Color.grayDivider)
            
            // Side dishes chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(order.sideDishes, id: \.self) { dish in
                        Text(dish)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.grayInput)
                            .foregroundStyle(Color.grayTextSecondary)
                            .cornerRadius(16)
                    }
                }
            }
            
        }
        .padding()
        .background(Color.graySurface)
        .cornerRadius(16)
        .shadow(color: Color.grayText.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    OrderCard(order: OrderItem.sampleOrders[0])
        .padding()
        .background(Color.grayBackground)
}
