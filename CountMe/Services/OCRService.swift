import Vision
import UIKit

final class OCRService {
    /// Process an image with OCR and return the recognized text in left-to-right, top-to-bottom order
    private func recognizeText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("Error processing OCR: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: "")
                    return
                }
                
                // Get all recognized text observations with their bounding boxes
                var textObservations: [(text: String, boundingBox: CGRect)] = []
                
                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        // Convert normalized coordinates to image coordinates
                        let boundingBox = CGRect(
                            x: observation.boundingBox.origin.x,
                            y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                            width: observation.boundingBox.width,
                            height: observation.boundingBox.height
                        )
                        
                        textObservations.append((candidate.string, boundingBox))
                    }
                }
                
                // Sort observations by their vertical position (top to bottom)
                // With tolerance to group text at similar vertical positions
                let lineHeight = textObservations.map { $0.boundingBox.height }.reduce(0, +) / CGFloat(textObservations.count)
                let tolerance = lineHeight * 0.5
                
                // Group observations into rows based on vertical position
                var rows: [[Int]] = []
                var currentRow: [Int] = []
                var lastYPosition: CGFloat = -1
                
                // Sort observations by Y position first
                let sortedIndices = textObservations.indices.sorted {
                    textObservations[$0].boundingBox.midY < textObservations[$1].boundingBox.midY
                }
                
                for index in sortedIndices {
                    let y = textObservations[index].boundingBox.midY
                    
                    if lastYPosition == -1 || abs(y - lastYPosition) <= tolerance {
                        // Same row
                        currentRow.append(index)
                    } else {
                        // New row
                        if !currentRow.isEmpty {
                            rows.append(currentRow)
                        }
                        currentRow = [index]
                    }
                    
                    lastYPosition = y
                }
                
                // Add the last row
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                
                // Sort each row horizontally (left to right)
                for i in 0..<rows.count {
                    rows[i].sort {
                        textObservations[$0].boundingBox.minX < textObservations[$1].boundingBox.minX
                    }
                }
                
                // Build the final text
                var result = ""
                
                for row in rows {
                    let rowTexts = row.map { textObservations[$0].text }
                    result += rowTexts.joined(separator: " ")
                    result += "\n"
                }
                
                continuation.resume(returning: result)
            }
            
            // Configure the request for accurate text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Create a request handler using the image
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Process the request
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error performing OCR request: \(error.localizedDescription)")
                continuation.resume(returning: "")
            }
        }
    }
    
    /// Process multiple images with OCR and report progress
    func batchRecognizeText(from images: [UIImage],
                            progressHandler: @escaping (Int, Int) -> Void) async -> [String] {
        var results: [String] = []
        
        for (index, image) in images.enumerated() {
            // Report progress
            progressHandler(index, images.count)
            
            // Process the image
            let text = await recognizeText(from: image)
            results.append(text)
        }
        
        return results
    }
}
