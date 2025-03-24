import SwiftData
import SwiftUI

/// Container for the app's SwiftData schema
enum AppSchema {
    static var container: ModelContainer = {
        let schema = Schema([
            OrderItem.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    /// Helper method to create a preview container with sample data
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            OrderItem.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // Add sample items for previews
            Task { @MainActor in
                let context = container.mainContext
                for order in OrderItem.sampleOrders {
                    context.insert(order)
                }
            }
            
            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }()
}
