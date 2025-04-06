//
//  ProofParserService.swift
//  CountMe
//
//  Created by Stephen Hau on 26/03/25.
//

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
    
    /// Parse OCR text into structured to proof  data
    func parseProof(from ocrText: String) -> ParsedProof {
        var proof = ParsedProof()
        proof.rawText = ocrText
        
        // Split the OCR text into lines
        let lines = ocrText.components(separatedBy: .newlines)
        
        // Extract date and order number
        for line in lines {
            if line.contains(":") {
                let dateString = extractValue(from: line, after: "")
                proof.dateTime = parseDate(dateString)
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
            if line.contains("IDR") {
                // Extract total payment
                if let totalPayment = extractPrice(from: line) {
                    proof.totalPayment = totalPayment
                }
            }
        }
        
        return proof
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
        dateFormatter.dateFormat = "dd Mmm yyyy HH:mm:ss"
        
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
