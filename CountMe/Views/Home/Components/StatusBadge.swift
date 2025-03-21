import SwiftUI

struct StatusBadge: View {
    let status: OrderItem.VerificationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .foregroundStyle(status.color)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadge(status: .verified)
        StatusBadge(status: .pending)
    }
    .padding()
}
