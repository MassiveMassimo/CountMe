import SwiftUI
import PhotosUI

class HomeViewModel: ObservableObject {
    // Services
    let ocrService = OCRService()
    private let receiptParserService = ReceiptParserService()
    
    // Published state
    @Published var orders: [OrderItem] = OrderItem.sampleOrders
    @Published var currentFilter: OrderFilter = .all
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var scannedImages: [UIImage] = []
    @Published var selectedImages: [UIImage] = [] // Images from photo library
    @Published var recognizedTexts: [String] = []
    @Published var parsedReceipts: [ParsedReceipt] = []
    @Published var isProcessing = false
    @Published var processingIndex = 0
    @Published var showingOCRResults = false
    @Published var orderBeingEdited: OrderItem? // Add this property
    
    // Computed properties
    var filteredOrders: [OrderItem] {
        switch currentFilter {
        case .all:
            return orders
        case .verified:
            return orders.filter { $0.verificationStatus == .verified }
        case .pending:
            return orders.filter { $0.verificationStatus == .pending }
        }
    }
    
    // MARK: - Order Management
    
    func deleteOrder(_ order: OrderItem) {
        withAnimation {
            orders.removeAll { $0.id == order.id }
        }
    }
    
    func editOrder(_ order: OrderItem) {
        print("Edit order: \(order.title)")
        // Implement order editing functionality
    }
    
    /// Create a new order from a parsed receipt
    func createOrderFromReceipt(_ receipt: ParsedReceipt) {
        // Create the main title from the main dish
        let title = receipt.mainDish
        
        // Format the date for display
        let dateTime = receipt.dateTime ?? Date()
        
        // Extract price
        let price = receipt.totalPrice
        
        // Create side dishes array
        let sideDishes = receipt.sideDishes.map { $0.name }
        
        // Create a new order
        let newOrder = OrderItem(
            title: title,
            dateTime: dateTime,
            price: price,
            sideDishes: sideDishes,
            verificationStatus: .pending
        )
        
        // Add to the orders list
        withAnimation {
            orders.insert(newOrder, at: 0)
        }
    }
    
    // MARK: - Image Processing
    
    /// Process selected photos from the photo library
    func processSelectedPhotos() async {
        guard !selectedPhotoItems.isEmpty else { return }
        
        // Reset previous data
        selectedImages = []
        recognizedTexts = []
        parsedReceipts = []
        processingIndex = 0
        
        await MainActor.run {
            isProcessing = true
        }
        
        // Load all images first
        for (index, item) in selectedPhotoItems.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                await MainActor.run {
                    selectedImages.append(uiImage)
                    processingIndex = index
                }
            }
        }
        
        // Then process OCR on all loaded images
        let texts = await ocrService.batchRecognizeText(from: selectedImages) { index, total in
            Task { @MainActor in
                self.processingIndex = index
            }
        }
        
        // Parse the recognized texts
        let receipts = texts.map { receiptParserService.parseReceipt(from: $0) }
        
        await MainActor.run {
            recognizedTexts = texts
            parsedReceipts = receipts
            isProcessing = false
            
            // Only show results if we have images
            if !selectedImages.isEmpty {
                showingOCRResults = true
            }
        }
    }
    
    /// Process scanned document images
    func processScannedDocuments() async {
        guard !scannedImages.isEmpty else { return }
        
        await MainActor.run {
            isProcessing = true
            recognizedTexts = []
            parsedReceipts = []
            processingIndex = 0
        }
        
        // Process OCR on all scanned images
        let texts = await ocrService.batchRecognizeText(from: scannedImages) { index, total in
            Task { @MainActor in
                self.processingIndex = index
            }
        }
        
        // Parse the recognized texts
        let receipts = texts.map { receiptParserService.parseReceipt(from: $0) }
        
        await MainActor.run {
            recognizedTexts = texts
            parsedReceipts = receipts
            isProcessing = false
            
            // Show results
            showingOCRResults = true
        }
    }
    
    /// Reset the image selection and processing state
    func resetImageSelection() {
        selectedPhotoItems = []
        selectedImages = []
        scannedImages = []
        recognizedTexts = []
        parsedReceipts = []
        isProcessing = false
        orderBeingEdited = nil  // Reset the order being edited
    }
    
    /// Save a parsed receipt to create a new order or update existing order
    func saveReceipt(at index: Int) {
        guard index < parsedReceipts.count else { return }
        
        if let orderToUpdate = orderBeingEdited {
            // Update the existing order with proof
            updateOrderWithProof(orderToUpdate, with: parsedReceipts[index])
        } else {
            // Create a new order
            createOrderFromReceipt(parsedReceipts[index])
        }
        
        // Reset orderBeingEdited
        orderBeingEdited = nil
    }
    
    /// Update an existing order with proof
    private func updateOrderWithProof(_ order: OrderItem, with receipt: ParsedReceipt) {
        // Find the order in the array
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            // Here you can decide what fields to update or validate
            
            // For example, if the receipt date and amount match, mark as verified
            let dateMatches = compareDate(order.dateTime, with: receipt.dateTime)
            let priceMatches = comparePrice(order.price, with: receipt.totalPrice)
            
            // Update the order
            var updatedOrder = order
            
            // If the proof matches, mark as verified
            if dateMatches && priceMatches {
                updatedOrder.verificationStatus = .verified
            } else {
                // You might want to add more status types or handle mismatches differently
                print("Proof mismatch. Date match: \(dateMatches), Price match: \(priceMatches)")
            }
            
            // Update the order in the array
            withAnimation {
                orders[index] = updatedOrder
            }
        }
    }
    
    // Helper methods for comparing order and receipt data
    private func compareDate(_ orderDate: Date, with receiptDate: Date?) -> Bool {
        guard let receiptDate = receiptDate else { return false }
        
        // Compare dates - you may want to be more flexible, e.g., same day rather than exact time
        let calendar = Calendar.current
        return calendar.isDate(orderDate, inSameDayAs: receiptDate)
    }
    
    private func comparePrice(_ orderPrice: Double, with receiptPrice: Double) -> Bool {
        // Compare prices with some tolerance (e.g., within 1%)
        let tolerance = 0.01 * orderPrice
        return abs(orderPrice - receiptPrice) <= tolerance
    }
}
