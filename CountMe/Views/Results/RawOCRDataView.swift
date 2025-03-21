import SwiftUI

struct RawOCRDataView: View {
    let rawText: String
    @Environment(\.dismiss) private var dismiss
    @State private var isCopying = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(rawText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Raw OCR Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = rawText
                        isCopying = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCopying = false
                        }
                    } label: {
                        Label(isCopying ? "Copied!" : "Copy All", systemImage: isCopying ? "checkmark" : "doc.on.doc")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RawOCRDataView(rawText: """
    Mama Djempol Binong
    Date : 17/03/2025 13:27
    Order Number : POS-170325-99
    Sales Type : Normal
    User : Binong
    Cashier : Binong
    ** REPRINT BILL **
    Daging Sapi lada
    Hitam
    1x 16.000 16. 000
    Kentang Mustopa
    1x 5.000 5.000
    Nasi Putih
    1x 4.000 4.000
    Total Item 3
    Total 25.000
    Tender
    Qris Mandiri 25.000
    Change 0
    """)
}
