import Foundation

struct ParsedReceipt {
    var restaurantName: String = ""
    var orderNumber: String = ""
    var dateTime: Date?
    var mainDish: String = ""
    var mainDishPrice: Double = 0.0
    var sideDishes: [(name: String, price: Double)] = []
    var totalPrice: Double = 0.0
    var paymentMethod: String = ""
    var rawText: String = ""
    
    var formattedDate: String {
        guard let date = dateTime else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var calculatedTotal: Double {
        return mainDishPrice + sideDishes.reduce(0) { $0 + $1.price }
    }
}

class ReceiptParserService {
    // Regular expressions for improved performance
    private let quantityLineRegex = try! NSRegularExpression(pattern: #"\d+\s*x\s+\d+\.?\d+"#)
    private let priceAtEndRegex = try! NSRegularExpression(pattern: #"\s+\d+\.?\d+$"#)
    private let standaloneNumberRegex = try! NSRegularExpression(pattern: #"^\d+\.?\d*$"#)
    
    /// Parse OCR text into structured receipt data
    func parseReceipt(from ocrText: String) -> ParsedReceipt {
        var receipt = ParsedReceipt()
        receipt.rawText = ocrText
        
        // Split the OCR text into lines and clean them
        let lines = ocrText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Skip empty receipts
        guard !lines.isEmpty else { return receipt }
        
        // Extract basic metadata
        receipt.restaurantName = lines[0]
        extractMetadata(from: lines, into: &receipt)
        extractTotal(from: lines, into: &receipt)
        extractPaymentMethod(from: lines, into: &receipt)
        
        // Process items
        let items = extractItems(from: lines)
        
        // Assign items to main dish and side dishes
        if !items.isEmpty {
            receipt.mainDish = items[0].name
            receipt.mainDishPrice = items[0].price
            
            if items.count > 1 {
                receipt.sideDishes = Array(items[1...])
            }
        }
        
        return receipt
    }
    
    // Extract date and order number
    private func extractMetadata(from lines: [String], into receipt: inout ParsedReceipt) {
        for line in lines {
            if line.lowercased().contains("date") {
                let dateString = extractValue(from: line, after: ":")
                receipt.dateTime = parseDate(dateString)
            } else if line.lowercased().contains("order number") {
                receipt.orderNumber = extractValue(from: line, after: ":")
            }
        }
    }
    
    // Extract total price
    private func extractTotal(from lines: [String], into receipt: inout ParsedReceipt) {
        for (i, line) in lines.enumerated() {
            // Format: "Total 25.000" (on same line)
            if line.starts(with: "Total") && !line.starts(with: "Total Item") {
                if let price = extractPrice(from: line) {
                    receipt.totalPrice = price
                    break
                }
                // Check next line if no price on this line
                else if i < lines.count - 1 {
                    let nextLine = lines[i+1]
                    if let price = extractPrice(from: nextLine) {
                        receipt.totalPrice = price
                        break
                    }
                }
            }
        }
    }
    
    // Extract payment method
    private func extractPaymentMethod(from lines: [String], into receipt: inout ParsedReceipt) {
        for (i, line) in lines.enumerated() {
            if line.contains("Tender") || line.contains("Payment") {
                if i < lines.count - 1 {
                    let paymentLine = lines[i+1]
                    receipt.paymentMethod = paymentLine.replacingOccurrences(
                        of: #"\s+\d+\.?\d*$"#,
                        with: "",
                        options: .regularExpression
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
    }
    
    // Extract dish items with improved multi-line detection
    private func extractItems(from lines: [String]) -> [(name: String, price: Double)] {
        // Find boundaries of the item section
        let startIdx = lines.firstIndex { $0.contains("REPRINT BILL") || $0.contains("==") } ?? 0
        let endIdx = lines.firstIndex { $0.contains("Total Item") || $0.contains("Total") } ?? lines.count
        
        guard startIdx < endIdx, startIdx + 1 < lines.count else {
            return []
        }
        
        // Find all quantity lines
        var quantityLines: [(index: Int, price: Double)] = []
        for i in (startIdx + 1)..<endIdx {
            if isQuantityLine(lines[i]), let price = extractPrice(from: lines[i]) {
                quantityLines.append((i, price))
            }
        }
        
        // Extract items from quantity lines
        return quantityLines.enumerated().compactMap { qIndex, itemInfo in
            let lineIndex = itemInfo.index
            let price = itemInfo.price
            
            // Collect item name parts by looking backward
            var nameIndex = lineIndex - 1
            var nameParts: [String] = []
            
            // Continue until another quantity line or section start
            while nameIndex > startIdx {
                let line = lines[nameIndex]
                
                // Stop conditions
                if isQuantityLine(line) || line.contains(":") {
                    break
                }
                
                // Add clean line to name parts
                let cleanLine = line.replacingOccurrences(
                    of: #"\s+\d+\.?\d*$"#,
                    with: "",
                    options: .regularExpression
                )
                nameParts.insert(cleanLine, at: 0)
                nameIndex -= 1
            }
            
            // Combine name parts and return item
            let name = nameParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : (name: name, price: price)
        }
    }
    
    // Check if a line contains a quantity pattern
    private func isQuantityLine(_ line: String) -> Bool {
        let range = NSRange(location: 0, length: line.utf16.count)
        return quantityLineRegex.firstMatch(in: line, options: [], range: range) != nil
    }
    
    // Extract value after a separator like ":"
    private func extractValue(from line: String, after separator: String) -> String {
        guard let range = line.range(of: separator) else { return "" }
        return line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Parse date string to Date object
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        
        if let date = dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return date
        }
        
        // Try alternative formats
        for format in ["MM/dd/yyyy HH:mm", "yyyy/MM/dd HH:mm"] {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        
        return nil
    }
    
    // Extract price from string (handling different formats)
    private func extractPrice(from text: String) -> Double? {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Case 1: Price at end of line like "Total 25.000"
        if let match = priceAtEndRegex.firstMatch(in: text, options: [], range: fullRange) {
            let priceStr = nsString.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            return convertToDouble(priceStr)
        }
        
        // Case 2: Standalone number like "25.000"
        if standaloneNumberRegex.firstMatch(in: text, options: [], range: fullRange) != nil {
            return convertToDouble(text)
        }
        
        // Case 3: Format with quantity "1x 16.000 16.000"
        if let match = quantityLineRegex.firstMatch(in: text, options: [], range: fullRange) {
            // Check if there's a second price after the quantity
            let afterMatchIdx = match.range.location + match.range.length
            if afterMatchIdx < nsString.length {
                let afterMatch = nsString.substring(from: afterMatchIdx).trimmingCharacters(in: .whitespacesAndNewlines)
                if !afterMatch.isEmpty, let secondPrice = convertToDouble(afterMatch) {
                    return secondPrice
                }
            }
            
            // Extract price from the quantity pattern
            let quantityStr = nsString.substring(with: match.range)
            if let priceRange = quantityStr.range(of: #"\d+\.?\d+$"#, options: .regularExpression) {
                let priceStr = String(quantityStr[priceRange])
                return convertToDouble(priceStr)
            }
        }
        
        return nil
    }
    
    // Convert Indonesian currency format to Double
    private func convertToDouble(_ priceString: String) -> Double? {
        // Handle zero as special case
        if priceString.trimmingCharacters(in: .whitespacesAndNewlines) == "0" {
            return 0.0
        }
        
        // Handle Indonesian format (25.000 = 25000)
        if priceString.contains(".") && !priceString.contains(",") {
            let sanitizedString = priceString.replacingOccurrences(of: ".", with: "")
            return Double(sanitizedString)
        }
        
        // Handle other formats
        let normalizedString = priceString.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedString)
    }
}
