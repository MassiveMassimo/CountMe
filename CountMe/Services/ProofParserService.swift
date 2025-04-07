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
    
    /// Parse OCR text into structured proof data
    func parseProof(from ocrText: String) -> ParsedProof {
        var proof = ParsedProof()
        proof.rawText = ocrText
        
        // Split the OCR text into lines
        let lines = ocrText.components(separatedBy: .newlines)
        
        // Common payment terms to look forprice i
        let dateKeywords = ["Date:", "Transaction Date:", "Tanggal:", "Waktu:", "Time:"]
        let amountKeywords = ["Amount:", "Total:", "Price:", "Rp", "IDR", "Jumlah:", "Pembayaran:"]
        
        // Extract date from specific line patterns first
        // Try to find a date in a common format directly
        for (index, line) in lines.enumerated() {
            // Look for date in dd/mm/yyyy format
            if line.range(of: #"\d{1,2}/\d{1,2}/\d{2,4}"#, options: .regularExpression) != nil {
                if let date = parseDate(line) {
                    proof.dateTime = date
                    break
                }
            }
            
            // Look for date in keyword labeled formats
            for keyword in dateKeywords {
                if line.contains(keyword) {
                    let dateString = extractValue(from: line, after: keyword)
                    if let date = parseDate(dateString) {
                        proof.dateTime = date
                        break
                    }
                }
            }
            
            // If we found a date, break out
            if proof.dateTime != nil {
                break
            }
        }
        
        // Extract payment amount - check every line for monetary patterns
        for line in lines {
            // Special handling for BCA transfer format
            if line.contains("Rp.") && line.contains(",") && line.contains(".") {
                if let totalPayment = extractPrice(from: line) {
                    proof.totalPayment = totalPayment
                    break
                }
            }
            
            // Check for amount patterns with keywords
            for keyword in amountKeywords {
                if line.contains(keyword) {
                    // Extract numbers from this line
                    if let totalPayment = extractPrice(from: line) {
                        proof.totalPayment = totalPayment
                        break
                    }
                }
            }
            
            // Look for patterns like numbers with "Rp" or currency symbol
            if line.range(of: #"(Rp\.?|IDR)\s*[0-9.,]+"#, options: .regularExpression) != nil ||
                line.range(of: #"[0-9.,]+\s*(Rp\.?|IDR)"#, options: .regularExpression) != nil {
                if let totalPayment = extractPrice(from: line) {
                    proof.totalPayment = totalPayment
                    break
                }
            }
            
            // Look for numbers ending with "000" - common in Indonesian money amounts
            if line.range(of: #"\b\d+[,.]000\b"#, options: .regularExpression) != nil {
                if let totalPayment = extractPrice(from: line) {
                    proof.totalPayment = totalPayment
                    break
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
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateFormatter = DateFormatter()
        
        // Try common formats
        let formats = [
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yy HH:mm:ss",
            "dd/MM/yyyy",
            "dd/MM/yy",
            "MM/dd/yyyy HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss",
            "dd MMM yyyy HH:mm:ss",
            "dd MMM yyyy",
            "dd-MM-yyyy",
            "dd-MM-yyyy HH:mm:ss",
            "yyyy-MM-dd",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: trimmed) {
                return date
            }
            
            // Try extracting just the date part (for cases with multiple information in one line)
            if let dateRegex = try? NSRegularExpression(pattern: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#) {
                let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                if let match = dateRegex.firstMatch(in: trimmed, range: nsRange),
                   let range = Range(match.range, in: trimmed) {
                    let dateSubstring = String(trimmed[range])
                    if format.contains("/") || format.contains("-") {
                        if let date = dateFormatter.date(from: dateSubstring) {
                            return date
                        }
                    }
                }
            }
            
            // Try extracting time part too
            if let dateTimeRegex = try? NSRegularExpression(pattern: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s+\d{1,2}:\d{1,2}(:\d{1,2})?"#) {
                let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                if let match = dateTimeRegex.firstMatch(in: trimmed, range: nsRange),
                   let range = Range(match.range, in: trimmed) {
                    let dateTimeSubstring = String(trimmed[range])
                    if format.contains("HH:mm") {
                        if let date = dateFormatter.date(from: dateTimeSubstring) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // Extract price from string (handling different formats)
    private func extractPrice(from text: String) -> Double? {
        // Common patterns to identify monetary amounts
        let patterns = [
            // BCA transfer format (like "Rp. 38,000.00")
            #"Rp\.?\s*([0-9]+[,.][0-9]+(?:[,.][0-9]+)?)"#,
            // Generic price pattern with currency symbol
            #"(?:Rp\.?|IDR)\s*([0-9]+[,.][0-9]*)"#,
            // Price with 000 ending (common in Indonesian format)
            #"([0-9]+[,.][0-9]*000)"#,
            // Just numbers ending with 000 (common in payment amounts)
            #"([0-9]+000(?:\.[0-9]+)?)"#,
            // Any number following the word "Total" or "Amount"
            #"(?:Total|Amount|Jumlah|Pembayaran)\s*:?\s*([0-9]+[,.][0-9]*)"#
        ]
        
        // Try each pattern
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, range: nsRange),
                   match.numberOfRanges > 1,
                   let captureRange = Range(match.range(at: 1), in: text) {
                    
                    let amountText = String(text[captureRange])
                    
                    // Handle BCA format specifically (38,000.00)
                    if amountText.contains(",") && amountText.contains(".") {
                        // In BCA format, comma is thousand separator, period is decimal
                        let sanitized = amountText.replacingOccurrences(of: ",", with: "")
                        if let amount = Double(sanitized) {
                            return amount
                        }
                    }
                    
                    // Handle Indonesian format (38.000 or 120.500)
                    if amountText.contains(".") && !amountText.contains(",") {
                        // Check if it follows the pattern of period followed by exactly 3 digits
                        if let regex = try? NSRegularExpression(pattern: #"[0-9]+\.[0-9]{3}$"#) {
                            let nsRange = NSRange(amountText.startIndex..<amountText.endIndex, in: amountText)
                            if regex.firstMatch(in: amountText, range: nsRange) != nil {
                                let sanitized = amountText.replacingOccurrences(of: ".", with: "")
                                if let amount = Double(sanitized) {
                                    return amount
                                }
                            }
                        }
                        
                        // Also check for amounts ending in 000
                        if amountText.hasSuffix("000") || amountText.hasSuffix(".000") {
                            let sanitized = amountText.replacingOccurrences(of: ".", with: "")
                            if let amount = Double(sanitized) {
                                return amount
                            }
                        }
                    }
                    
                    // Try standard conversion after replacing comma with period
                    let normalizedString = amountText.replacingOccurrences(of: ",", with: ".")
                    if let amount = Double(normalizedString) {
                        return amount
                    }
                }
            }
        }
        
        // Additional fallback for simple format: just look for numbers ending with three zeros
        if let regex = try? NSRegularExpression(pattern: #"\b([0-9]+)000\b"#) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, range: nsRange),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: text) {
                
                let baseNumber = String(text[captureRange])
                if let base = Double(baseNumber) {
                    return base * 1000
                }
            }
        }
        
        // Last resort: extract all number sequences and look for candidates
        if let regex = try? NSRegularExpression(pattern: #"[0-9]+"#) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, range: nsRange)
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let numberStr = String(text[range])
                    // Check if this could be an amount (typically > 1000 for a payment)
                    if let number = Double(numberStr), number >= 1000 {
                        return number
                    }
                }
            }
        }
        
        return nil
    }
}
