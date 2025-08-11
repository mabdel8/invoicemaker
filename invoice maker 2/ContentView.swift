//
//  ContentView.swift
//  invoice maker 2
//
//  Created by Mohamed Abdelmagid on 8/10/25.
//

import SwiftUI
import WebKit
import PDFKit

// Simple data model for invoice
struct InvoiceData {
    var companyName = "My Company"
    var companyAddress = "123 Business Street"
    var companyCity = "New York, NY 10001"
    var companyPhone = "(555) 123-4567"
    var companyEmail = "hello@mycompany.com"
    
    var clientName = "Client Name"
    var clientAddress = "456 Client Street"
    var clientCity = "Brooklyn, NY 11201"
    var clientEmail = "client@email.com"
    
    var invoiceNumber = "INV-001"
    var invoiceDate = "December 8, 2024"
    var dueDate = "January 7, 2025"
    var paymentTerms = "NET-30"
    
    var subtotal = "$1,000.00"
    var taxRate = "8.25"
    var taxAmount = "$82.50"
    var total = "$1,082.50"
    var notes = "Thank you for your business!"
    
    var items: [OldInvoiceItem] = [
        OldInvoiceItem(name: "Service 1", description: "Professional consulting", quantity: "1", rate: "$500.00", amount: "$500.00"),
        OldInvoiceItem(name: "Service 2", description: "Additional support", quantity: "1", rate: "$500.00", amount: "$500.00")
    ]
}

// Old InvoiceItem struct for PDF generation compatibility
struct OldInvoiceItem: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var quantity: String
    var rate: String
    var amount: String
}

// PDF Generator
class SimplePDFGenerator: NSObject, ObservableObject {
    @Published var isGenerating = false
    @Published var generatedPDF: PDFDocument?
    
    private var webView: WKWebView?
    private var completion: ((PDFDocument?) -> Void)?
    
    override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        
        // Configure preferences for better rendering
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Create webview with letter width but extended height to render all content
        // The extended height allows all content to render before pagination
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 5000), configuration: config)
        webView?.navigationDelegate = self
        
        // Configure scrollView for proper rendering
        webView?.scrollView.isScrollEnabled = true
        webView?.scrollView.showsVerticalScrollIndicator = false
        webView?.scrollView.showsHorizontalScrollIndicator = false
    }
    
    func generatePDF(from invoiceData: InvoiceData, completion: @escaping (PDFDocument?) -> Void) {
        self.completion = completion
        isGenerating = true
        
        let htmlContent = createHTML(from: invoiceData)
        webView?.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func createHTML(from data: InvoiceData) -> String {
        let itemsHTML = data.items.map { item in
            """
            <tr class="item-row">
                <td class="item-description-cell">
                    <div class="item-name">\(item.name)</div>
                    <div class="item-description-text">\(item.description)</div>
                </td>
                <td class="item-quantity-cell">\(item.quantity)</td>
                <td class="item-rate-cell">\(item.rate)</td>
                <td class="item-amount-cell">\(item.amount)</td>
            </tr>
            """
        }.joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
            @page {
                size: 8.5in 11in;
                margin: 0.5in;
            }
            
            @media print {
                body {
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                }
                
                .invoice-container {
                    page-break-after: always;
                }
            }
            
            * { margin: 0; padding: 0; box-sizing: border-box; }
            
            html {
                width: 100%;
            }
            
            body { 
                font-family: Arial, sans-serif; 
                font-size: 11px; 
                line-height: 1.3; 
                color: #333;
                background: white;
                margin: 0;
                padding: 0;
                width: 100%;
                orphans: 3;
                widows: 3;
            }
            
            .invoice-container { 
                width: 100%;
                margin: 0;
                padding: 30px;
                background: white;
                box-sizing: border-box;
                page-break-after: auto;
            }
            
            .header { 
                display: flex; 
                justify-content: space-between; 
                align-items: flex-start;
                margin-bottom: 20px; 
                padding-bottom: 15px;
                border-bottom: 2px solid #f0f0f0;
            }
            
            .company-info h1 { 
                font-size: 20px; 
                font-weight: 300; 
                color: #333; 
                margin-bottom: 3px;
            }
            
            .company-info p { 
                font-size: 10px; 
                color: #666; 
                margin-bottom: 1px;
            }
            
            .invoice-title-section { text-align: right; }
            
            .invoice-title { 
                font-size: 28px; 
                font-weight: 300; 
                color: #333; 
                letter-spacing: 1px;
                margin-bottom: 3px;
            }
            
            .invoice-details {
                display: flex;
                justify-content: space-between;
                margin-bottom: 20px;
                gap: 30px;
            }
            
            .invoice-meta {
                text-align: right;
                flex: 1;
                max-width: 200px;
            }
            
            .meta-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 3px;
                font-size: 10px;
            }
            
            .meta-label {
                font-weight: 500;
                color: #666;
                min-width: 70px;
            }
            
            .meta-value {
                font-weight: 600;
                color: #333;
                text-align: right;
            }
            
            .bill-to { 
                margin: 0; 
                flex: 1;
            }
            
            .bill-to h3 {
                font-size: 12px;
                font-weight: 600;
                color: #333;
                margin-bottom: 6px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .bill-to .client-name {
                font-weight: 600;
                color: #333;
                margin-bottom: 2px;
                font-size: 11px;
            }
            
            .bill-to p {
                font-size: 10px;
                color: #666;
                margin-bottom: 1px;
            }
            
            .items-table { 
                width: 100%; 
                border-collapse: collapse; 
                margin: 15px 0; 
                page-break-inside: auto;
                break-inside: auto;
            }
            
            .items-table thead {
                display: table-header-group; /* Repeat header on each page */
            }
            
            .items-table tbody {
                display: table-row-group;
            }
            
            .items-table th, .items-table td { 
                padding: 8px; 
                text-align: left; 
                border-bottom: 1px solid #f0f0f0; 
            }
            
            .item-row {
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .items-table tr {
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .totals-section {
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .notes {
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .table-header { 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                color: white; 
            }
            
            .table-header th {
                font-weight: 600;
                font-size: 10px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .item-name {
                font-weight: 600;
                color: #333;
                margin-bottom: 2px;
                font-size: 10px;
            }
            
            .item-description-text {
                font-size: 9px;
                color: #666;
                line-height: 1.2;
            }
            
            .item-quantity-cell { text-align: center; font-size: 10px; }
            .item-rate-cell, .item-amount-cell { 
                text-align: right; 
                font-family: 'Courier New', monospace;
                font-weight: 500;
                font-size: 10px;
            }
            
            .totals-section {
                display: flex;
                justify-content: flex-end;
                margin: 20px 0;
            }
            
            .totals-container {
                width: 220px;
                background: #fafafa;
                border: 1px solid #e0e0e0;
                border-radius: 6px;
                padding: 15px;
            }
            
            .totals-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 5px;
                padding: 2px 0;
                font-size: 10px;
            }
            
            .total-label {
                font-weight: 500;
                color: #666;
            }
            
            .total-value {
                font-weight: 600;
                color: #333;
                font-family: 'Courier New', monospace;
            }
            
            .total-final {
                border-top: 1px solid #d0d0d0;
                border-bottom: 2px solid #333;
                padding: 6px 0;
                margin: 6px 0;
            }
            
            .total-final .total-label,
            .total-final .total-value {
                font-size: 12px;
                font-weight: 700;
                color: #333;
            }
            
            .notes {
                margin-top: 20px;
                padding-top: 15px;
                border-top: 1px solid #f0f0f0;
            }
            
            .notes h4 {
                font-size: 12px;
                font-weight: 600;
                color: #333;
                margin-bottom: 5px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .notes p {
                color: #666;
                line-height: 1.4;
                font-size: 10px;
            }
            
            /* Enhanced page break handling */
            .header {
                page-break-after: avoid;
                break-after: avoid;
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .invoice-details {
                page-break-after: avoid;
                break-after: avoid;
                page-break-inside: avoid;
                break-inside: avoid;
            }
            
            .items-table {
                page-break-inside: auto;
                break-inside: auto;
            }            </style>
        </head>
        <body>
            <div class="invoice-container">
                <div class="header">
                    <div class="company-info">
                        <h1>\(data.companyName)</h1>
                        <p>\(data.companyAddress)</p>
                        <p>\(data.companyCity)</p>
                        <p>\(data.companyPhone)</p>
                        <p>\(data.companyEmail)</p>
                    </div>
                    <div class="invoice-title-section">
                        <div class="invoice-title">INVOICE</div>
                        <p>#\(data.invoiceNumber)</p>
                    </div>
                </div>
                
                <div class="invoice-details">
                    <div class="bill-to">
                        <h3>BILL TO</h3>
                        <div class="client-name">\(data.clientName)</div>
                        <p>\(data.clientAddress)</p>
                        <p>\(data.clientCity)</p>
                        <p>\(data.clientEmail)</p>
                    </div>
                    
                    <div class="invoice-meta">
                        <div class="meta-row">
                            <span class="meta-label">Date:</span>
                            <span class="meta-value">\(data.invoiceDate)</span>
                        </div>
                        <div class="meta-row">
                            <span class="meta-label">Due Date:</span>
                            <span class="meta-value">\(data.dueDate)</span>
                        </div>
                        <div class="meta-row">
                            <span class="meta-label">Terms:</span>
                            <span class="meta-value">\(data.paymentTerms)</span>
                        </div>
                    </div>
                </div>
                
                <table class="items-table">
                    <thead>
                        <tr class="table-header">
                            <th>Service Description</th>
                            <th>Quantity</th>
                            <th>Rate</th>
                            <th>Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        \(itemsHTML)
                    </tbody>
                </table>
                
                <div class="totals-section">
                    <div class="totals-container">
                        <div class="totals-row">
                            <span class="total-label">Subtotal:</span>
                            <span class="total-value">\(data.subtotal)</span>
                        </div>
                        <div class="totals-row">
                            <span class="total-label">Tax (\(data.taxRate)%):</span>
                            <span class="total-value">\(data.taxAmount)</span>
                        </div>
                        <div class="totals-row total-final">
                            <span class="total-label">Total:</span>
                            <span class="total-value">\(data.total)</span>
                        </div>
                    </div>
                </div>
                
                <div class="notes">
                    <h4>Notes</h4>
                    <p>\(data.notes)</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
}

extension SimplePDFGenerator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait for content to fully render before creating PDF
        // Increased time ensures complex invoices render completely
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createPaginatedPDF(from: webView)
        }
    }
    
    private func createPaginatedPDF(from webView: WKWebView) {
        // Create a custom print page renderer
        let renderer = CustomPrintPageRenderer()
        let printFormatter = webView.viewPrintFormatter()
        
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        // Letter size at 72 DPI
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let printableRect = CGRect(x: 36, y: 36, width: 540, height: 720)
        
        renderer.setValue(pageRect, forKey: "paperRect") 
        renderer.setValue(printableRect, forKey: "printableRect")
        
        // Generate PDF data
        let pdfData = renderer.generatePDFData()
        
        DispatchQueue.main.async { [weak self] in
            self?.isGenerating = false
            
            if let pdf = PDFDocument(data: pdfData) {
                self?.generatedPDF = pdf
                self?.completion?(pdf)
                print("✅ PDF generated with \(pdf.pageCount) page(s)")
                
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i) {
                        let bounds = page.bounds(for: .mediaBox)
                        print("  - Page \(i+1): \(bounds.width) x \(bounds.height) points")
                    }
                }
            } else {
                print("❌ Failed to create PDFDocument")
                self?.completion?(nil)
            }
        }
    }
}

// Custom print page renderer for multi-page PDFs
class CustomPrintPageRenderer: UIPrintPageRenderer {
    
    func generatePDFData() -> Data {
        let pdfData = NSMutableData()
        
        // Start PDF context
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        
        // Prepare for drawing
        self.prepare(forDrawingPages: NSRange(location: 0, length: self.numberOfPages))
        
        let bounds = UIGraphicsGetPDFContextBounds()
        
        // Render each page
        for pageIndex in 0..<self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: pageIndex, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
}

// PDF Viewer
struct PDFViewer: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        
        // Configure for continuous scrolling to show all pages
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Enable user interaction for scrolling through pages
        pdfView.usePageViewController(false)
        
        // IMPORTANT: Set autoScales AFTER setting the document
        // This ensures the PDF fits the width of the screen
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        
        // Set minimum and maximum scale for better viewing
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 4.0
        
        // Log page count for debugging
        let pageCount = pdfDocument.pageCount
        print("PDF Viewer: Document has \(pageCount) page(s)")
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

// Main View
struct ContentView: View {
    @StateObject private var pdfGenerator = SimplePDFGenerator()
    @State private var invoiceData = InvoiceData()
    @State private var showingPDF = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Company Information") {
                        TextField("Company Name", text: $invoiceData.companyName)
                        TextField("Address", text: $invoiceData.companyAddress)
                        TextField("City, State ZIP", text: $invoiceData.companyCity)
                        TextField("Phone", text: $invoiceData.companyPhone)
                        TextField("Email", text: $invoiceData.companyEmail)
                    }
                    
                    Section("Invoice Details") {
                        TextField("Invoice Number", text: $invoiceData.invoiceNumber)
                        TextField("Invoice Date", text: $invoiceData.invoiceDate)
                        TextField("Due Date", text: $invoiceData.dueDate)
                        TextField("Payment Terms", text: $invoiceData.paymentTerms)
                    }
                    
                    Section("Client Information") {
                        TextField("Client Name", text: $invoiceData.clientName)
                        TextField("Client Address", text: $invoiceData.clientAddress)
                        TextField("Client City, State ZIP", text: $invoiceData.clientCity)
                        TextField("Client Email", text: $invoiceData.clientEmail)
                    }
                    
                    Section("Invoice Totals") {
                        TextField("Subtotal", text: $invoiceData.subtotal)
                        TextField("Tax Rate (%)", text: $invoiceData.taxRate)
                        TextField("Tax Amount", text: $invoiceData.taxAmount)
                        TextField("Total Amount", text: $invoiceData.total)
                    }
                    
                    Section("Invoice Items") {
                        ForEach(invoiceData.items.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("Item \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if invoiceData.items.count > 1 {
                                        Button("Remove") {
                                            invoiceData.items.remove(at: index)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                }
                                
                                TextField("Service Name", text: $invoiceData.items[index].name)
                                TextField("Description", text: $invoiceData.items[index].description)
                                HStack {
                                    TextField("Qty", text: $invoiceData.items[index].quantity)
                                        .frame(maxWidth: 60)
                                    TextField("Rate", text: $invoiceData.items[index].rate)
                                    TextField("Amount", text: $invoiceData.items[index].amount)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        
                        Button("Add Item") {
                            addNewItem()
                        }
                        .foregroundColor(.blue)
                        
                        Button("Add 10 Test Items") {
                            addTestItems()
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Section("Notes") {
                        TextField("Notes", text: $invoiceData.notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                // Generate PDF Button
                VStack(spacing: 15) {
                    Button(action: generatePDF) {
                        HStack {
                            if pdfGenerator.isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "doc.fill")
                            }
                            Text(pdfGenerator.isGenerating ? "Generating PDF..." : "Generate PDF")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(pdfGenerator.isGenerating)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Invoice Generator")
            .sheet(isPresented: $showingPDF) {
                if let pdf = pdfGenerator.generatedPDF {
                    NavigationView {
                        PDFViewer(pdfDocument: pdf)
                            .navigationTitle("Invoice PDF")
                            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Done") {
                                        showingPDF = false
                                    }
                                }
                                
                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Share") {
                                        // Add share functionality
                                        sharePDF(pdf)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func generatePDF() {
        pdfGenerator.generatePDF(from: invoiceData) { pdf in
            if pdf != nil {
                showingPDF = true
            }
        }
    }
    
    private func addNewItem() {
        let newItem = OldInvoiceItem(
            name: "New Service",
            description: "Service description",
            quantity: "1",
            rate: "$100.00",
            amount: "$100.00"
        )
        invoiceData.items.append(newItem)
    }
    
    private func addTestItems() {
        let testItems = [
            OldInvoiceItem(name: "Web Design", description: "Custom website design and development", quantity: "1", rate: "$2,500.00", amount: "$2,500.00"),
            OldInvoiceItem(name: "SEO Optimization", description: "Search engine optimization for better rankings", quantity: "3", rate: "$300.00", amount: "$900.00"),
            OldInvoiceItem(name: "Content Writing", description: "Professional content creation for website", quantity: "5", rate: "$150.00", amount: "$750.00"),
            OldInvoiceItem(name: "Logo Design", description: "Brand identity and logo creation", quantity: "1", rate: "$800.00", amount: "$800.00"),
            OldInvoiceItem(name: "Social Media Setup", description: "Social media account setup and optimization", quantity: "4", rate: "$200.00", amount: "$800.00"),
            OldInvoiceItem(name: "E-commerce Integration", description: "Online store setup with payment processing", quantity: "1", rate: "$1,500.00", amount: "$1,500.00"),
            OldInvoiceItem(name: "Mobile App Development", description: "iOS and Android app development", quantity: "1", rate: "$5,000.00", amount: "$5,000.00"),
            OldInvoiceItem(name: "Database Setup", description: "Database design and implementation", quantity: "2", rate: "$400.00", amount: "$800.00"),
            OldInvoiceItem(name: "Training Session", description: "Staff training on new systems", quantity: "6", rate: "$100.00", amount: "$600.00"),
            OldInvoiceItem(name: "Maintenance Contract", description: "Annual website maintenance and support", quantity: "1", rate: "$1,200.00", amount: "$1,200.00")
        ]
        
        invoiceData.items.append(contentsOf: testItems)
    }
    
    private func sharePDF(_ pdf: PDFDocument) {
        guard let data = pdf.dataRepresentation() else { 
            print("Failed to get PDF data for sharing")
            return 
        }
        
        // Create a temporary file URL with proper filename
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Invoice_\(invoiceData.invoiceNumber).pdf")
        
        do {
            // Write PDF data to temporary file
            try data.write(to: tempURL)
            
            // Create activity view controller with the file URL
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            // For iPad compatibility
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = UIView()
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, 
                                                      y: UIScreen.main.bounds.midY, 
                                                      width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                // Find the top-most presented view controller
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error preparing PDF for sharing: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
