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
    }
    
    /// Save a parsed receipt to create a new order
    func saveReceipt(at index: Int) {
        guard index < parsedReceipts.count else { return }
        
        createOrderFromReceipt(parsedReceipts[index])
    }
}
