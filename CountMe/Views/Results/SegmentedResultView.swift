import SwiftUI
import SwiftData

struct SegmentedResultView: View {
    let images: [UIImage]
    let recognizedTexts: [String]
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    @State private var showSaveConfirmation = false
    @State private var retakePhotoIndex: Int? = nil
    @State private var showRetakeOptions = false
    
    var body: some View {
        
        NavigationStack {
            VStack {
                if images.isEmpty {
                    ContentUnavailableView(
                        label: { Label("No Images", systemImage: "photo") },
                        description: { Text("No images were selected or processed") }
                    )
                } else {
                    // Tab selector for multiple images
                    if images.count > 1 {
                        Picker("Select Receipt", selection: $selectedTab) {
                            ForEach(0..<images.count, id: \.self) { index in
                                Text("\(index + 1)").tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                    
                    // Main content
                    if viewModel.orderBeingEdited != nil && !viewModel.parsedProofs.isEmpty && selectedTab < viewModel.parsedProofs.count {
                        // Display proof details when we're in proof verification mode
                        ProofDetailView(
                            parsedProof: viewModel.parsedProofs[selectedTab],
                            proofImage: images[selectedTab],
                            onSave: { updatedProof in
                                // Update the parsed proof in the view model
                                viewModel.parsedProofs[selectedTab] = updatedProof
                                
                                // Save the proof and update order
                                viewModel.saveReceipt(at: selectedTab)
                                
                                // Show confirmation and dismiss after delay
                                showSaveConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            },
                            onRetake: {
                                retakePhotoIndex = selectedTab
                                showRetakeOptions = true
                            }
                        )
                    } else if !viewModel.parsedReceipts.isEmpty && selectedTab < viewModel.parsedReceipts.count {
                        // Display receipt details when we're adding a new receipt
                        ReceiptDetailView(
                            parsedReceipt: viewModel.parsedReceipts[selectedTab],
                            receiptImage: images[selectedTab],
                            onSave: { updatedReceipt in
                                // Update the parsed receipt in the view model
                                viewModel.parsedReceipts[selectedTab] = updatedReceipt
                                
                                // Create a new order from this receipt
                                viewModel.saveReceipt(at: selectedTab)
                                
                                // Show confirmation and dismiss after delay
                                showSaveConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            },
                            onRetake: {
                                retakePhotoIndex = selectedTab
                                showRetakeOptions = true
                            }
                        )
                    } else {
                        // Show loading or image with raw text
                        ScrollView {
                            VStack(alignment: .center, spacing: 20) {
                                if selectedTab < images.count {
                                    ZStack(alignment: .bottomTrailing) {
                                        Image(uiImage: images[selectedTab])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                            
                                        // Retake button
                                        Button(action: {
                                            retakePhotoIndex = selectedTab
                                            showRetakeOptions = true
                                        }) {
                                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Circle().fill(Color.accentColor))
                                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                                        }
                                        .padding([.bottom, .trailing], 24)
                                    }
                                }
                                
                                if viewModel.isProcessing {
                                    ProgressView("Analyzing receipt...")
                                        .padding()
                                } else if selectedTab < recognizedTexts.count {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("Recognized Text:")
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            Button {
                                                UIPasteboard.general.string = recognizedTexts[selectedTab]
                                            } label: {
                                                Label("Copy", systemImage: "doc.on.doc")
                                            }
                                        }
                                        
                                        Text(recognizedTexts[selectedTab].isEmpty ? "No text recognized" : recognizedTexts[selectedTab])
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                    .padding(.horizontal)
                                    
                                    Button(viewModel.orderBeingEdited != nil ? "Parse Proof Manually" : "Parse Receipt Manually") {
                                        if viewModel.orderBeingEdited != nil {
                                            // Parse as proof if we're in proof mode
                                            let parser = ProofParserService()
                                            let parsedProof = parser.parseProof(from: recognizedTexts[selectedTab])
                                            
                                            // Update or add to viewModel's parsedProofs
                                            if selectedTab < viewModel.parsedProofs.count {
                                                viewModel.parsedProofs[selectedTab] = parsedProof
                                            } else {
                                                viewModel.parsedProofs.append(parsedProof)
                                            }
                                        } else {
                                            // Parse as receipt if we're in receipt mode
                                            let parser = ReceiptParserService()
                                            let parsedReceipt = parser.parseReceipt(from: recognizedTexts[selectedTab])
                                            
                                            // Update or add to viewModel's parsedReceipts
                                            if selectedTab < viewModel.parsedReceipts.count {
                                                viewModel.parsedReceipts[selectedTab] = parsedReceipt
                                            } else {
                                                viewModel.parsedReceipts.append(parsedReceipt)
                                            }
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.orderBeingEdited != nil ? "Payment Proof" : "Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
            .overlay {
                if showSaveConfirmation {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text(viewModel.orderBeingEdited != nil ? "Proof Verified!" : "Order Added!")
                                .font(.headline)
                                .padding(.top)
                        }
                        .padding(30)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .shadow(radius: 10)
                    }
                }
            }
            .confirmationDialog(
                "Retake Receipt",
                isPresented: $showRetakeOptions
            ) {
                Button("Take a photo") {
                    guard let index = retakePhotoIndex else { return }
                    // Logic to retake photo would go here
                    // For now, just dismiss and let the main view handle it
                    dismiss()
                }
                Button("Choose from gallery") {
                    guard let index = retakePhotoIndex else { return }
                    // Logic to select from gallery would go here
                    // For now, just dismiss and let the main view handle it
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    retakePhotoIndex = nil
                }
            } message: {
                Text("Select input method")
            }
        }
    }
}

