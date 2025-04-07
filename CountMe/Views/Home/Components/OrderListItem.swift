import SwiftData
import SwiftUI

struct OrderListItem: View {
    let order: OrderItem
    @State private var showEditView = false
    @State private var showScanProofView = false
    @State private var showConfirmationDialog: Bool = false
    @Environment(\.modelContext) private var modelContext  // Inject SwiftData context
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                StatusBadge(status: order.verificationStatus)
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text(order.dateTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                Spacer().frame(width: 16)

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
                showEditView = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)

            if order.verificationStatus == .pending {
                Button {
                    showScanProofView = true
                } label: {
                    Label("Scan Proof", systemImage: "doc.text.viewfinder")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing) {
            // When using swipeActions, use a simple action that sets the state
            Button(role: .destructive) {
                // The dialog will be shown via .confirmationDialog modifier
                showConfirmationDialog.toggle()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        // This confirmation dialog is tied to the whole cell
        .confirmationDialog(
            "Delete Order",
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteOrder()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this order?")
        }
        // Add sheet for EditVerifiedView
        .sheet(isPresented: $showEditView) {
            // On dismiss callback if needed
        } content: {
            // Get images from order data if available
            let receiptUIImage = order.receiptImage != nil ?
                UIImage(data: order.receiptImage!) ?? UIImage(systemName: "doc.text")! :
                UIImage(systemName: "doc.text")!
            
            let proofUIImage = order.proofImage != nil ?
                UIImage(data: order.proofImage!) ?? UIImage(systemName: "photo")! :
                UIImage(systemName: "photo")!
            
            EditVerifiedView(
                order: order,
                receiptImage: receiptUIImage,
                onSave: { updatedOrder in
                    // SwiftData will automatically track changes to the order
                    // Additional logic if needed after saving
                },
                paymentProofImage: proofUIImage
            )
        }
        // Sheet for scan proof functionality (assuming it connects to HomeViewModel)
        .sheet(isPresented: $showScanProofView) {
            // This would be your scan proof implementation
            // For now, just a placeholder that informs the user
            VStack {
                Text("Scan Proof")
                    .font(.title)
                Text("This would launch your document scanner.")
                    .padding()
                Button("Close") {
                    showScanProofView = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
        }
    }

    private func deleteOrder() {
        withAnimation {
            modelContext.delete(order)
            do {
                try modelContext.save()
                print("Order deleted successfully")
            } catch {
                print("Failed to delete order: \(error)")
            }
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer
    let order = OrderItem.sampleOrders[0]

    return List {
        OrderListItem(order: order)
    }
    .modelContainer(container)
}
