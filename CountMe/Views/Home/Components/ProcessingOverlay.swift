import SwiftUI

struct ProcessingOverlay: View {
    let isVisible: Bool
    let currentIndex: Int
    let totalCount: Int
    
    private var progress: Double {
        guard totalCount > 1 else { return 0 }
        return Double(currentIndex + 1) / Double(totalCount)
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.4)
                VStack {
                    if totalCount > 1 {
                        ProgressView(value: progress)
                            .scaleEffect(1.5)
                            .tint(.white)
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    Text("Processing \(currentIndex + 1) of \(totalCount) images...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.7)))
            }
            .ignoresSafeArea()
        } else {
            EmptyView()
        }
    }
}
