import Foundation

struct ParsedReceipt {
    var restaurantName: String = ""
    var orderNumber: String = ""
    var dateTime: Date?
    var mainDish: String = ""
    var mainDishPrice: Double = 0.0
    var sideDishes: [(name: String, price: Double)] = []
    var totalPrice: Double = 0.0
    var rawText: String = ""
    
    // Format the date in a readable format
    var formattedDate: String {
        guard let date = dateTime else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Calculate total price from items
    var calculatedTotal: Double {
        return mainDishPrice + sideDishes.reduce(0) { $0 + $1.price }
    }
}

class ReceiptParserService {
    
    /// Parse OCR text into structured receipt data
    func parseReceipt(from ocrText: String) -> ParsedReceipt {
        var receipt = ParsedReceipt()
        receipt.rawText = ocrText
        
        // Split the OCR text into lines
        let lines = ocrText.components(separatedBy: .newlines)
        
        // Extract restaurant name (usually the first line)
        if !lines.isEmpty {
            receipt.restaurantName = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract date and order number
        for line in lines {
            if line.contains("Date") {
                let dateString = extractValue(from: line, after: ":")
                receipt.dateTime = parseDate(dateString)
            } else if line.contains("Order Number") {
                receipt.orderNumber = extractValue(from: line, after: ":")
            }
        }
        
        // Extract main dish and side dishes
        var foundMainDish = false
        var currentItemName = ""
        var currentItemQuantity = 0
        var currentItemPrice = 0.0
        
        for (index, line) in lines.enumerated() {
            // Skip header lines
            if index < 5 || line.isEmpty {
                continue
            }
            
            // Check if line contains price pattern (e.g., "1x 16.000 16.000")
            if line.contains("x ") && line.range(of: #"\d+\.\d+"#, options: .regularExpression) != nil {
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                
                // Try to extract quantity and price
                if components.count >= 3 {
                    let quantityPart = components[0]
                    let quantity = Int(quantityPart.replacingOccurrences(of: "x", with: "")) ?? 1
                    
                    // Get the last component as price
                    if let price = extractPrice(from: components.last ?? "") {
                        // Look back for item name
                        if index > 0 {
                            currentItemName = lines[index-1].trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Special case: Multi-line item name (like "Daging Sapi lada" + "Hitam")
                            if index > 1 && !foundMainDish && !lines[index-2].contains(":") && !lines[index-2].contains("REPRINT") {
                                currentItemName = "\(lines[index-2].trimmingCharacters(in: .whitespacesAndNewlines)) \(currentItemName)"
                            }
                        }
                        
                        currentItemQuantity = quantity
                        currentItemPrice = price
                        
                        // First item with price is considered the main dish
                        if !foundMainDish {
                            receipt.mainDish = currentItemName
                            receipt.mainDishPrice = currentItemPrice
                            foundMainDish = true
                        } else {
                            // Add as side dish
                            receipt.sideDishes.append((name: currentItemName, price: currentItemPrice))
                        }
                        
                        // Reset for next item
                        currentItemName = ""
                        currentItemQuantity = 0
                        currentItemPrice = 0.0
                    }
                }
            } else if line.contains("Total") && !line.contains("Item") && !line.contains("Tender") {
                // Extract total price
                if let totalPrice = extractPrice(from: line) {
                    receipt.totalPrice = totalPrice
                }
            }
        }
        
        return receipt
    }
    
    // Helper method to extract value after a separator
    private func extractValue(from line: String, after separator: String) -> String {
        if let range = line.range(of: separator) {
            let afterSeparator = line[range.upperBound...]
            return afterSeparator.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    // Parse date string to Date object
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        
        // Try parsing with the expected format
        if let date = dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return date
        }
        
        // Try alternative formats if needed
        let alternativeFormats = ["MM/dd/yyyy HH:mm", "yyyy/MM/dd HH:mm"]
        for format in alternativeFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        
        return nil
    }
    
    // Extract price from string (handling different formats)
    private func extractPrice(from text: String) -> Double? {
        // Remove any non-numeric characters except for period and comma
        let priceString = text.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        
        // Special handling for Indonesian currency format (25.000 means 25000, not 25)
        // Check if the string looks like Indonesian format with period as thousand separator
        if priceString.contains(".") && !priceString.contains(",") {
            // Remove the periods and convert
            let sanitizedString = priceString.replacingOccurrences(of: ".", with: "")
            return Double(sanitizedString)
        }
        
        // Handle different number formats (e.g., 16,000 with comma as decimal separator)
        let normalizedString = priceString.replacingOccurrences(of: ",", with: ".")
        
        // Try to convert to Double
        return Double(normalizedString)
    }
}
