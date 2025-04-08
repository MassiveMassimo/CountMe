import SwiftUI
import PhotosUI
import SwiftData

@Observable
class HomeViewModel {
    // Services
    let ocrService = OCRService()
    private let receiptParserService = ReceiptParserService()
    private let proofParserService = ProofParserService()
    
    // SwiftData ModelContext
    private var modelContext: ModelContext
    
    // State properties (no need for @Published)
    var currentFilter: OrderFilter = .all
    var selectedPhotoItems: [PhotosPickerItem] = []
    var scannedImages: [UIImage] = []
    var selectedImages: [UIImage] = []
    var recognizedTexts: [String] = []
    var parsedReceipts: [ParsedReceipt] = []
    var parsedProofs: [ParsedProof] = []
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
        print("Edit order: \(order.orderNumber)")
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
        // Use orderNumber directly as requested
        let orderNumber = receipt.orderNumber
        
        // Format the date for display
        let dateTime = receipt.dateTime ?? Date()
        
        // Extract price
        let price = receipt.totalPrice
        
        // Create dishes array from all dishes in the receipt
        let dishNames = receipt.dishes.map { $0.name }
        
        // Convert image to data if provided
        var imageData: Data? = nil
        if let image = image, let jpegData = image.jpegData(compressionQuality: 0.7) {
            imageData = jpegData
        }
        
        // Create a new order
        let newOrder = OrderItem(
            orderNumber: orderNumber,
            dateTime: dateTime,
            price: price,
            receiptImage: imageData,
            dishes: dishNames,
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
        parsedProofs = []
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
        
        // Parse the recognized texts based on whether we're processing a proof or receipt
        if orderBeingEdited != nil {
            // We're processing a proof
            let proofs = texts.map { proofParserService.parseProof(from: $0) }
            
            await MainActor.run {
                recognizedTexts = texts
                parsedProofs = proofs
                isProcessing = false
                
                // Only show results if we have images
                if !selectedImages.isEmpty {
                    showingOCRResults = true
                }
            }
        } else {
            // We're processing a receipt
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
    }
    
    /// Process scanned document images
    func processScannedDocuments() async {
        guard !scannedImages.isEmpty else { return }
        
        await MainActor.run {
            isProcessing = true
            recognizedTexts = []
            parsedReceipts = []
            parsedProofs = []
            processingIndex = 0
        }
        
        // Process OCR on all scanned images
        let texts = await ocrService.batchRecognizeText(from: scannedImages) { index, total in
            Task { @MainActor in
                self.processingIndex = index
            }
        }
        
        // Parse the recognized texts based on whether we're processing a proof or receipt
        if orderBeingEdited != nil {
            // We're processing a proof
            let proofs = texts.map { proofParserService.parseProof(from: $0) }
            
            await MainActor.run {
                recognizedTexts = texts
                parsedProofs = proofs
                isProcessing = false
                
                // Show results
                showingOCRResults = true
            }
        } else {
            // We're processing a receipt
            let receipts = texts.map { receiptParserService.parseReceipt(from: $0) }
            
            await MainActor.run {
                recognizedTexts = texts
                parsedReceipts = receipts
                isProcessing = false
                
                // Show results
                showingOCRResults = true
            }
        }
    }
    
    /// Reset the image selection and processing state
    func resetImageSelection() {
        selectedPhotoItems = []
        selectedImages = []
        scannedImages = []
        recognizedTexts = []
        parsedReceipts = []
        parsedProofs = []
        isProcessing = false
        orderBeingEdited = nil  // Reset the order being edited
    }
    
    /// Save a parsed receipt or proof to create a new order or update existing order
    func saveReceipt(at index: Int) {
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
            // Ensure index is valid for parsed proofs
            guard index < parsedProofs.count else { return }
            
            // Update the existing order with proof
            updateOrderWithProof(orderToUpdate, with: parsedProofs[index], proofImage: imageToSave)
        } else {
            // Ensure index is valid for parsed receipts
            guard index < parsedReceipts.count else { return }
            
            // Create a new order
            createOrderFromReceipt(parsedReceipts[index], image: imageToSave)
        }
        
        // Reset orderBeingEdited
        orderBeingEdited = nil
    }
    
    /// Update an existing order with proof
    private func updateOrderWithProof(_ order: OrderItem, with proof: ParsedProof, proofImage: UIImage?) {
        // Convert proof image to data if provided
        if let image = proofImage, let jpegData = image.jpegData(compressionQuality: 0.7) {
            order.proofImage = jpegData
        }
        
        // Only check if the price matches for verification
        let priceMatches = comparePrice(order.price, with: proof.totalPayment)
        
        // If the price matches, mark as verified, otherwise mark as mismatch
        if priceMatches {
            order.verificationStatus = .verified
        } else {
            order.verificationStatus = .mismatch
            print("Proof mismatch. Price match: \(priceMatches), Order price: \(order.price), Proof price: \(proof.totalPayment)")
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
