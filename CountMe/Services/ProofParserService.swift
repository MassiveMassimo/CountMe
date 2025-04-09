import Foundation

struct ParsedProof {
    var dateTime: Date?
    var totalPayment: Double = 0.0
    var rawText: String = ""
    
    // Format the date in a readable format
    var formattedDate: String {
        guard let date = dateTime else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

class ProofParserService {
    // Common regex patterns compiled once
    private let datePatterns: [NSRegularExpression] = {
        return [
            try! NSRegularExpression(pattern: #"\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+\d{1,2}:\d{1,2}:\d{1,2}"#),  // QRIS format
            try! NSRegularExpression(pattern: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#),                           // dd/mm/yyyy
            try! NSRegularExpression(pattern: #"\d{4}[/-]\d{1,2}[/-]\d{1,2}"#)                              // yyyy-mm-dd
        ]
    }()
    
    private let pricePatterns: [NSRegularExpression] = {
        return [
            try! NSRegularExpression(pattern: #"(?:IDR|Rp\.?)\s*([0-9.,]+)"#),                             // Combined IDR/Rp pattern
            try! NSRegularExpression(pattern: #"(?:Total|Amount|Jumlah|Pembayaran)\s*:?\s*([0-9.,]+)"#),   // Keywords
            try! NSRegularExpression(pattern: #"([0-9]+[,.][0-9]*000)"#),                                  // Price with 000 ending
            try! NSRegularExpression(pattern: #"\b([0-9]+)000\b"#)                                         // Simple 000 suffix
        ]
    }()
    
    // Common keywords
    private let dateKeywords = ["Date:", "Transaction Date:", "Tanggal:", "Waktu:", "Time:"]
    private let amountKeywords = ["Amount:", "Total:", "Price:", "Rp", "IDR", "Jumlah:", "Pembayaran:"]
    
    // Date formatter - reuse a single instance
    private let dateFormatter = DateFormatter()
    
    /// Parse OCR text into structured proof data
    func parseProof(from ocrText: String) -> ParsedProof {
        var proof = ParsedProof()
        proof.rawText = ocrText
        
        // Split the OCR text into lines
        let lines = ocrText.components(separatedBy: .newlines)
        
        // First pass - extract date and amount in a single loop for efficiency
        for line in lines {
            // Try to find date if we don't have one yet
            if proof.dateTime == nil {
                if let date = findDate(in: line) {
                    proof.dateTime = date
                }
            }
            
            // Try to find amount
            if proof.totalPayment == 0.0 {
                if let amount = extractPrice(from: line) {
                    proof.totalPayment = amount
                }
            }
            
            // If we've found both, we can stop processing
            if proof.dateTime != nil && proof.totalPayment != 0.0 {
                break
            }
        }
        
        return proof
    }
    
    // Consolidated date finding method
    private func findDate(in line: String) -> Date? {
        // First try using regex patterns
        for pattern in datePatterns {
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = pattern.firstMatch(in: line, range: nsRange),
               let range = Range(match.range, in: line) {
                let dateString = String(line[range])
                if let date = parseDate(dateString) {
                    return date
                }
            }
        }
        
        // Then try keyword-based detection
        for keyword in dateKeywords {
            if line.contains(keyword) {
                let dateString = extractValue(from: line, after: keyword)
                if let date = parseDate(dateString) {
                    return date
                }
            }
        }
        
        return nil
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
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Common date formats - ordered by likelihood
        let formats = [
            "dd MMM yyyy HH:mm:ss",  // QRIS format (09 Apr 2025 14:11:15)
            "dd/MM/yyyy",            // Common format (05/04/2025)
            "dd/MM/yyyy HH:mm:ss",
            "yyyy-MM-dd",            // ISO format (2025-04-07)
            "yyyy-MM-dd HH:mm:ss",
            "dd-MM-yyyy",
            "dd-MM-yyyy HH:mm:ss",
            "dd/MM/yy",
            "MM/dd/yyyy",
            "dd MMM yyyy"
        ]
        
        // Try each format
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: trimmed) {
                return date
            }
        }
        
        return nil
    }
    
    // Extract price from string (handling different formats)
    private func extractPrice(from text: String) -> Double? {
        // Quick check for common prefixes
        let lowercaseText = text.lowercased()
        if !(lowercaseText.contains("rp") ||
             lowercaseText.contains("idr") ||
             lowercaseText.contains("total") ||
             lowercaseText.contains("amount") ||
             text.contains("000") ||
             text.contains(",") ||
             text.contains(".")) {
            return nil // Skip lines unlikely to contain prices
        }
        
        // First try with precompiled patterns
        for pattern in pricePatterns {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = pattern.firstMatch(in: text, range: nsRange),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: text) {
                
                let amountText = String(text[captureRange])
                
                // Process the amount based on the format
                if let amount = processAmountText(amountText) {
                    return amount
                }
            }
        }
        
        // If we got this far and the text has "IDR" or "Rp" and digits, try direct extraction
        if (lowercaseText.contains("idr") || lowercaseText.contains("rp")) &&
            lowercaseText.range(of: #"[0-9]"#, options: .regularExpression) != nil {
            
            // Extract all potential numbers
            if let regex = try? NSRegularExpression(pattern: #"[0-9.,]+"#) {
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
                let matches = regex.matches(in: text, range: nsRange)
                
                for match in matches.reversed() { // Try later numbers first (usually the amount)
                    if let range = Range(match.range, in: text) {
                        let amountText = String(text[range])
                        if let amount = processAmountText(amountText), amount > 0 {
                            return amount
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // Centralized amount text processing
    private func processAmountText(_ amountText: String) -> Double? {
        // BCA format (9,000.00) - comma as thousands separator, period as decimal
        if amountText.contains(",") && amountText.contains(".") {
            let sanitized = amountText.replacingOccurrences(of: ",", with: "")
            return Double(sanitized)
        }
        
        // Indonesian format (9.000) - period as thousands separator
        if amountText.contains(".") && !amountText.contains(",") &&
            (amountText.hasSuffix("000") || amountText.range(of: #"\.[0-9]{3}$"#, options: .regularExpression) != nil) {
            let sanitized = amountText.replacingOccurrences(of: ".", with: "")
            return Double(sanitized)
        }
        
        // Try standard numeric parsing (with comma as decimal)
        let normalizedString = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedString)
    }
}
