import Foundation

struct ParsedReceipt {
    //change data types to optional
    var restaurantName: String = ""
    var orderNumber: String = ""
    var dateTime: Date?
    var dishes: [(name: String, price: Double)] = []
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
        return dishes.reduce(0) { $0 + $1.price }
    }
}

class ReceiptParserService {
    // Regular expressions for improved performance
    private let quantityLineRegex = try! NSRegularExpression(pattern: #"\d+\s*x\s+\d+\.?\d+"#)
    private let priceAtEndRegex = try! NSRegularExpression(pattern: #"\s+\d+\.?\d+$"#)
    private let standaloneNumberRegex = try! NSRegularExpression(pattern: #"^\d+\.?\d*$"#)
    private let dateRegex = try! NSRegularExpression(pattern: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s+\d{1,2}:\d{1,2}"#)
    private let orderNumberRegex = try! NSRegularExpression(pattern: #"(?:Order\s*Number|No\.?)\s*[:\•\.\-]?\s*([\w\d\-]+)"#, options: [.caseInsensitive])
    
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
        receipt.restaurantName = extractRestaurantName(from: lines)
        extractMetadata(from: lines, into: &receipt)
        extractTotal(from: lines, into: &receipt)
        extractPaymentMethod(from: lines, into: &receipt)
        
        // Process items and assign to dishes array
        receipt.dishes = extractItems(from: lines)
        
        return receipt
    }
    
    // Extract restaurant name, handling multi-line possibilities
    private func extractRestaurantName(from lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }
        
        // Often the restaurant name is the first non-empty line, but sometimes it spans multiple lines
        // before we encounter date/order information
        var nameLines: [String] = []
        for line in lines {
            // Stop if we encounter metadata markers
            if line.lowercased().contains("date") ||
                line.lowercased().contains("order") ||
                line.lowercased().contains(":") ||
                line.contains("==") {
                break
            }
            nameLines.append(line)
        }
        
        return nameLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Extract date and order number with improved detection
    private func extractMetadata(from lines: [String], into receipt: inout ParsedReceipt) {
        // First try to find date and order number using regex patterns across all lines
        let nsText = lines.joined(separator: "\n") as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        // Extract date
        if let dateMatch = dateRegex.firstMatch(in: nsText as String, options: [], range: fullRange) {
            let dateString = nsText.substring(with: dateMatch.range)
            receipt.dateTime = parseDate(dateString)
        }
        
        // Extract order number
        if let orderMatch = orderNumberRegex.firstMatch(in: nsText as String, options: [], range: fullRange),
           orderMatch.numberOfRanges > 1 {
            let orderNumberRange = orderMatch.range(at: 1)
            if orderNumberRange.location != NSNotFound {
                let extractedOrderNumber = nsText.substring(with: orderNumberRange)
                // Only use if it looks like a valid order number (more than 2 characters)
                if extractedOrderNumber.count > 2 {
                    receipt.orderNumber = extractedOrderNumber
                }
            }
        }
        
        // Fallback to line-by-line search if not found
        if receipt.dateTime == nil || receipt.orderNumber.isEmpty {
            for line in lines {
                // Look for date
                if receipt.dateTime == nil {
                    if line.lowercased().contains("date") {
                        let dateString = extractValue(from: line, after: ":")
                        receipt.dateTime = parseDate(dateString)
                    } else if let date = parseDate(line) {
                        // Try direct date parsing on the line
                        receipt.dateTime = date
                    }
                }
                
                // Look for order number
                if receipt.orderNumber.isEmpty && line.lowercased().contains("order number") {
                    receipt.orderNumber = extractValue(from: line, after: ":")
                }
            }
        }
    }
    
    // Extract total price
    private func extractTotal(from lines: [String], into receipt: inout ParsedReceipt) {
        for (i, line) in lines.enumerated() {
            // Format: "Total 25.000" (on same line)
            if line.lowercased().contains("total") && !line.lowercased().contains("total item") {
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
    
    // Extract payment method with improved detection
    private func extractPaymentMethod(from lines: [String], into receipt: inout ParsedReceipt) {
        var tenderFound = false
        
        for (i, line) in lines.enumerated() {
            if line.lowercased().contains("tender") ||
                line.lowercased().contains("payment") {
                tenderFound = true
                
                // Look for payment method in the next few lines
                let searchLimit = min(lines.count, i + 4)
                for j in (i+1)..<searchLimit {
                    let paymentLine = lines[j]
                    
                    // Skip change line or lines containing just numbers
                    if paymentLine.lowercased().contains("change") ||
                        standaloneNumberRegex.firstMatch(in: paymentLine, options: [], range: NSRange(location: 0, length: paymentLine.utf16.count)) != nil {
                        continue
                    }
                    
                    // Extract payment method, removing any trailing price
                    let method = paymentLine.replacingOccurrences(
                        of: #"\s+\d+\.?\d*$"#,
                        with: "",
                        options: .regularExpression
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !method.isEmpty {
                        receipt.paymentMethod = method
                        return
                    }
                }
            }
        }
        
        // If "Tender" wasn't found, look for payment-like methods in the last part of the receipt
        if !tenderFound {
            let searchStart = max(0, lines.count - 10)
            let paymentKeywords = ["cash", "card", "credit", "debit", "visa", "master", "qris", "gopay", "ovo", "dana"]
            
            for i in searchStart..<lines.count {
                let line = lines[i].lowercased()
                if !line.contains("total") && !line.contains("change") &&
                    paymentKeywords.contains(where: { line.contains($0) }) {
                    receipt.paymentMethod = lines[i].replacingOccurrences(
                        of: #"\s+\d+\.?\d*$"#,
                        with: "",
                        options: .regularExpression
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
    }
    
    // Extract dish items with improved multi-line detection and handling special markers
    private func extractItems(from lines: [String]) -> [(name: String, price: Double)] {
        var items: [(name: String, price: Double)] = []
        
        // Find boundaries of the item section
        let startIdx = lines.firstIndex(where: {
            $0.contains("REPRINT BILL") ||
            $0.contains("==") ||
            $0.contains("ITEM") ||
            $0.contains("QTY")
        }) ?? 0
        
        // For the end index, look specifically for "Total Item" or standalone "Total"
        let endIdx = lines.firstIndex(where: { line in
            let lowercaseLine = line.lowercased()
            return lowercaseLine.contains("total item") ||
            lowercaseLine.contains("sub total") ||
            (lowercaseLine.contains("total") && !lowercaseLine.contains("x"))
        }) ?? lines.count
        
        guard startIdx < endIdx, startIdx + 1 < lines.count else {
            return []
        }
        
        // Identify all quantity lines first (lines that match our quantity pattern)
        var quantityLines: [(index: Int, price: Double)] = []
        for i in (startIdx + 1)..<endIdx {
            if isQuantityLine(lines[i]), let price = extractPrice(from: lines[i]) {
                quantityLines.append((i, price))
            }
        }
        
        // For each quantity line, try to extract the item
        for (qIdx, (lineIdx, price)) in quantityLines.enumerated() {
            // First, check if the current line contains the item name
            // (For cases like "Nasi Putih 1x 4.000 4.000")
            let currentLine = lines[lineIdx]
            let nameBeforeQuantity = extractNameBeforeQuantity(from: currentLine)
            
            if !nameBeforeQuantity.isEmpty {
                // If we found a name in the current line, use it directly
                items.append((name: nameBeforeQuantity, price: price))
                continue
            }
            
            // Otherwise, look backward to collect all lines that might be part of the item name
            var currentLineIdx = lineIdx - 1
            var nameParts: [String] = []
            var collectingName = true
            var nameEndBoundary = startIdx
            
            // If this isn't the first item, set boundary to previous quantity line
            if qIdx > 0 {
                nameEndBoundary = quantityLines[qIdx-1].index + 1
            }
            
            // Continue looking backward until we hit a boundary
            while currentLineIdx >= nameEndBoundary && collectingName {
                let currentLine = lines[currentLineIdx]
                
                // Skip special markers that shouldn't be part of item names
                if currentLine.contains("REPRINT BILL") ||
                    currentLine.contains("==") ||
                    currentLine.contains("ITEM") ||
                    currentLine.contains("QTY") {
                    currentLineIdx -= 1
                    continue
                }
                
                // Stop if line contains metadata markers or another quantity
                if isQuantityLine(currentLine) ||
                    currentLine.contains(":") ||
                    currentLine.lowercased().contains("date") ||
                    currentLine.lowercased().contains("order") {
                    collectingName = false
                } else {
                    // Clean the line (remove any trailing price)
                    let cleanLine = currentLine.replacingOccurrences(
                        of: #"\s+\d+\.?\d*$"#,
                        with: "",
                        options: .regularExpression
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Add to name parts if not empty and doesn't contain noise
                    let noiseWords = ["BILL", "RECEIPT", "INVOICE"]
                    if !cleanLine.isEmpty && !noiseWords.contains(where: { cleanLine.contains($0) }) {
                        nameParts.insert(cleanLine, at: 0)
                    }
                    currentLineIdx -= 1
                }
            }
            
            // If no name was found looking backward, try to use the current line itself
            if nameParts.isEmpty {
                let currentLine = lines[lineIdx]
                let cleanCurrentLine = currentLine.replacingOccurrences(
                    of: #"\d+\s*x\s+\d+\.?\d+"#,
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanCurrentLine.isEmpty {
                    nameParts.append(cleanCurrentLine)
                }
            }
            
            // Combine all parts and add to items
            let itemName = nameParts.joined(separator: " ")
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "REPRINT BILL", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !itemName.isEmpty {
                // Clean up common OCR noise in the name
                let cleanedName = cleanItemName(itemName)
                items.append((name: cleanedName, price: price))
            }
        }
        
        return items
    }
    
    // Extract a name from a line that might have both name and quantity pattern
    private func extractNameBeforeQuantity(from line: String) -> String {
        // Check if this line has a format like "Nasi Putih 1x 4.000 4.000"
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        
        if let quantityMatch = quantityLineRegex.firstMatch(in: line, options: [], range: range) {
            // Extract everything before the quantity pattern
            let beforeQuantity = nsLine.substring(to: quantityMatch.range.location)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !beforeQuantity.isEmpty {
                return cleanItemName(beforeQuantity)
            }
        }
        
        return ""
    }
    
    // Clean up common OCR noise from item names
    private func cleanItemName(_ name: String) -> String {
        var cleaned = name
        
        // Remove random numbers that appear at the beginning (common OCR artifacts)
        cleaned = cleaned.replacingOccurrences(of: #"^\d+\s+"#, with: "", options: .regularExpression)
        
        // Remove other common noise patterns
        let noisePatterns = ["**", "*", "REPRINT", "BILL", "==="]
        for pattern in noisePatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "")
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    // Parse date string to Date object with more flexible format handling
    private func parseDate(_ dateString: String) -> Date? {
        // Normalize the date string first (handle different separators)
        let normalizedDateString = dateString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "/")
        
        let dateFormatter = DateFormatter()
        
        // Try common date formats
        let dateFormats = [
            "dd/MM/yyyy HH:mm",
            "MM/dd/yyyy HH:mm",
            "yyyy/MM/dd HH:mm",
            "d/M/yyyy HH:mm",
            "d/M/yy HH:mm"
        ]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: normalizedDateString) {
                return date
            }
        }
        
        // If that fails, try to extract date information using regex
        let nsString = normalizedDateString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        if let match = dateRegex.firstMatch(in: normalizedDateString, options: [], range: range) {
            let matchedDate = nsString.substring(with: match.range)
            
            // Try parsing the extracted date with our formats
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: matchedDate) {
                    return date
                }
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
