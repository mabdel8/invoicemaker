//
//  PDFPreviewView.swift
//  invoice maker 2
//
//  PDF preview with inline viewer and export/share actions
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfDocument: PDFDocument
    let invoice: Invoice
    let onDismiss: (() -> Void)? // Optional closure to handle parent dismissal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreKitManager
    @State private var showingFullPDF = false
    @State private var showingShareSheet = false
    @State private var showingExportSuccess = false
    @State private var exportError: String?
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Inline PDF Preview (Thumbnail)
                PDFThumbnailView(pdfDocument: pdfDocument)
                    .onTapGesture {
                        showingFullPDF = true
                    }
                
                // Action Buttons
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Export Button
                        Button(action: {
                            if storeManager.isSubscribed() {
                                exportPDF()
                            } else {
                                showingPaywall = true
                            }
                        }) {
                            HStack {
                                Label("Export", systemImage: "square.and.arrow.down")
                                if !storeManager.isSubscribed() {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(storeManager.isSubscribed() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Share Button
                        Button(action: {
                            if storeManager.isSubscribed() {
                                showingShareSheet = true
                            } else {
                                showingPaywall = true
                            }
                        }) {
                            HStack {
                                Label("Share", systemImage: "square.and.arrow.up")
                                if !storeManager.isSubscribed() {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(storeManager.isSubscribed() ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    // View Full PDF Button
                    Button(action: {
                        showingFullPDF = true
                    }) {
                        Label("View Full PDF", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    // Invoice Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Invoice #\(invoice.invoiceNumber)")
                                .font(.headline)
                            Spacer()
                            Text(invoice.formattedTotal)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text(invoice.clientName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.formattedInvoiceDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        // Call the onDismiss closure to dismiss parent view if provided
                        onDismiss?()
                    }
                }
            }
            .sheet(isPresented: $showingFullPDF) {
                FullPDFView(pdfDocument: pdfDocument)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(pdfDocument: pdfDocument, invoice: invoice)
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView(isModal: true)
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK") { }
            } message: {
                Text("Invoice has been saved to your Files app")
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") {
                    exportError = nil
                }
            } message: {
                Text(exportError ?? "")
            }
        }
    }
    
    private func exportPDF() {
        guard let data = pdfDocument.dataRepresentation() else {
            exportError = "Failed to generate PDF data"
            return
        }
        
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask)[0]
        let fileName = "Invoice_\(invoice.invoiceNumber).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            showingExportSuccess = true
        } catch {
            exportError = "Failed to save PDF: \(error.localizedDescription)"
        }
    }
}

// PDF Thumbnail View
struct PDFThumbnailView: View {
    let pdfDocument: PDFDocument
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Label("Tap to view full PDF", systemImage: "magnifyingglass")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .padding()
                            }
                        }
                    )
            } else {
                ProgressView("Loading preview...")
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard let page = pdfDocument.page(at: 0) else { return }
        
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // For retina display
        let thumbnailSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))
            
            context.cgContext.saveGState()
            
            // Fix coordinate system - PDFs use bottom-left origin, UIKit uses top-left
            // First translate to bottom, then flip vertically
            context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            // Draw the PDF page
            page.draw(with: .mediaBox, to: context.cgContext)
            
            context.cgContext.restoreGState()
        }
        
        thumbnailImage = image
    }
}

// Full PDF View
struct FullPDFView: View {
    let pdfDocument: PDFDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(pdfDocument: pdfDocument)
                .navigationTitle("Invoice PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// PDFKit View Wrapper
struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        
        // Configure for proper display
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 4.0
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let pdfDocument: PDFDocument
    let invoice: Invoice
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        guard let data = pdfDocument.dataRepresentation() else {
            return UIActivityViewController(activityItems: [], applicationActivities: nil)
        }
        
        // Create temporary file with proper name
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Invoice_\(invoice.invoiceNumber).pdf")
        
        try? data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        // iPad compatibility
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX,
                                       y: UIScreen.main.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PDFPreviewView(
        pdfDocument: PDFDocument(),
        invoice: Invoice(),
        onDismiss: nil
    )
}