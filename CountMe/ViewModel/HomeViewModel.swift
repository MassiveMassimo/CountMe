import SwiftUI
import PhotosUI
import SwiftData

@Observable
class HomeViewModel {
    // Services
    let ocrService = OCRService()
    private let receiptParserService = ReceiptParserService()
    
    // SwiftData ModelContext
    private var modelContext: ModelContext
    
    // State properties (no need for @Published)
    var currentFilter: OrderFilter = .all
    var selectedPhotoItems: [PhotosPickerItem] = []
    var scannedImages: [UIImage] = []
    var selectedImages: [UIImage] = []
    var recognizedTexts: [String] = []
    var parsedReceipts: [ParsedReceipt] = []
    var isProcessing = false
    var processingIndex = 0
    var showingOCRResults = false
    var orderBeingEdited: OrderItem?
    
    // Initialize with ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        // Store the provided model context
        self.modelContext = newContext
    }
    
    // Function to fetch orders with optional sorting and filtering
    func fetchOrders(filter: OrderFilter = .all) -> [OrderItem] {
        let descriptor = FetchDescriptor<OrderItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        do {
            let orders = try modelContext.fetch(descriptor)
            
            // Apply filter if needed
            switch filter {
            case .all:
                return orders
            case .verified:
                return orders.filter { $0.verificationStatus == .verified }
            case .pending:
                return orders.filter { $0.verificationStatus == .pending }
            }
        } catch {
            print("Failed to fetch orders: \(error)")
            return []
        }
    }
    
    
    // MARK: - Order Management
    
    func deleteOrder(_ order: OrderItem) {
        modelContext.delete(order)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete order: \(error)")
        }
    }
    
    func editOrder(_ order: OrderItem) {
        print("Edit order: \(order.title)")
        // Implement order editing functionality
        
        // After editing, save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save edited order: \(error)")
        }
    }
    
    /// Create a new order from a parsed receipt
    func createOrderFromReceipt(_ receipt: ParsedReceipt, image: UIImage? = nil) {
        // Create the main title from the main dish
        let title = receipt.mainDish
        
        // Format the date for display
        let dateTime = receipt.dateTime ?? Date()
        
        // Extract price
        let price = receipt.totalPrice
        
        // Create side dishes array
        let sideDishes = receipt.sideDishes.map { $0.name }
        
        // Convert image to data if provided
        var imageData: Data? = nil
        if let image = image, let jpegData = image.jpegData(compressionQuality: 0.7) {
            imageData = jpegData
        }
        
        // Create a new order
        let newOrder = OrderItem(
            title: title,
            dateTime: dateTime,
            price: price,
            receiptImage: imageData,
            sideDishes: sideDishes,
            verificationStatus: .pending
        )
        
        // Add to SwiftData
        modelContext.insert(newOrder)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new order: \(error)")
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
        
        // Determine which image to save (scanned or selected)
        let imageToSave: UIImage?
        if !scannedImages.isEmpty && index < scannedImages.count {
            imageToSave = scannedImages[index]
        } else if !selectedImages.isEmpty && index < selectedImages.count {
            imageToSave = selectedImages[index]
        } else {
            imageToSave = nil
        }
        
        if let orderToUpdate = orderBeingEdited {
            // Update the existing order with proof
            updateOrderWithProof(orderToUpdate, with: parsedReceipts[index], proofImage: imageToSave)
        } else {
            // Create a new order
            createOrderFromReceipt(parsedReceipts[index], image: imageToSave)
        }
        
        // Reset orderBeingEdited
        orderBeingEdited = nil
    }
    
    /// Update an existing order with proof
    private func updateOrderWithProof(_ order: OrderItem, with receipt: ParsedReceipt, proofImage: UIImage?) {
        // Convert proof image to data if provided
        if let image = proofImage, let jpegData = image.jpegData(compressionQuality: 0.7) {
            order.proofImage = jpegData
        }
        
        // Check if the receipt date and amount match for verification
        let dateMatches = compareDate(order.dateTime, with: receipt.dateTime)
        let priceMatches = comparePrice(order.price, with: receipt.totalPrice)
        
        // If the proof matches, mark as verified
        if dateMatches && priceMatches {
            order.verificationStatus = .verified
        } else {
            // You might want to add more status types or handle mismatches differently
            print("Proof mismatch. Date match: \(dateMatches), Price match: \(priceMatches)")
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to update order with proof: \(error)")
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
