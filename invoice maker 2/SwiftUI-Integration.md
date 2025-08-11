# SwiftUI Integration Guide

## Overview
This guide shows how to integrate the HTML invoice template into a SwiftUI app for generating professional PDF invoices.

## Approach 1: WebKit + HTML Template (Recommended)

### 1. Create the Invoice Data Model

```swift
import Foundation

struct InvoiceData: Codable {
    // Company Information
    let companyName: String
    let companyTagline: String?
    let companyLogo: String? // Base64 or URL
    let companyAddress1: String
    let companyAddress2: String
    let companyPhone: String
    let companyEmail: String
    let companyWebsite: String?
    
    // Invoice Details
    let invoiceNumber: String
    let invoiceDate: String
    let dueDate: String
    let paymentTerms: String
    let poNumber: String?
    let currency: String
    
    // Client Information
    let clientName: String
    let clientAddress1: String
    let clientAddress2: String?
    let clientEmail: String?
    let clientPhone: String?
    
    // Items
    let items: [InvoiceItem]
    
    // Financial Totals
    let subtotal: String
    let taxRate: String?
    let taxAmount: String?
    let discountAmount: String?
    let totalAmount: String
    let amountPaid: String?
    let balanceDue: String
    
    // Additional Info
    let notes: String?
    let terms: String?
    let footerText: String?
}

struct InvoiceItem: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let quantity: String
    let rate: String
    let amount: String
}
```

### 2. HTML Template Manager

```swift
import Foundation

class InvoiceTemplateManager {
    static let shared = InvoiceTemplateManager()
    
    private init() {}
    
    func loadTemplate() -> String? {
        guard let path = Bundle.main.path(forResource: "invoice-template", ofType: "html"),
              let template = try? String(contentsOfFile: path) else {
            return nil
        }
        return template
    }
    
    func populateTemplate(with data: InvoiceData, theme: InvoiceTheme = .blue) -> String? {
        guard var template = loadTemplate() else { return nil }
        
        // Replace company information
        template = template.replacingOccurrences(of: "{{COMPANY_NAME}}", with: data.companyName)
        template = template.replacingOccurrences(of: "{{COMPANY_TAGLINE}}", with: data.companyTagline ?? "")
        template = template.replacingOccurrences(of: "{{COMPANY_LOGO}}", with: data.companyLogo ?? "")
        template = template.replacingOccurrences(of: "{{COMPANY_ADDRESS_LINE_1}}", with: data.companyAddress1)
        template = template.replacingOccurrences(of: "{{COMPANY_ADDRESS_LINE_2}}", with: data.companyAddress2)
        template = template.replacingOccurrences(of: "{{COMPANY_PHONE}}", with: data.companyPhone)
        template = template.replacingOccurrences(of: "{{COMPANY_EMAIL}}", with: data.companyEmail)
        template = template.replacingOccurrences(of: "{{COMPANY_WEBSITE}}", with: data.companyWebsite ?? "")
        
        // Replace invoice details
        template = template.replacingOccurrences(of: "{{INVOICE_NUMBER}}", with: data.invoiceNumber)
        template = template.replacingOccurrences(of: "{{INVOICE_DATE}}", with: data.invoiceDate)
        template = template.replacingOccurrences(of: "{{DUE_DATE}}", with: data.dueDate)
        template = template.replacingOccurrences(of: "{{PAYMENT_TERMS}}", with: data.paymentTerms)
        template = template.replacingOccurrences(of: "{{PO_SO_NUMBER}}", with: data.poNumber ?? "")
        template = template.replacingOccurrences(of: "{{CURRENCY}}", with: data.currency)
        
        // Replace client information
        template = template.replacingOccurrences(of: "{{CLIENT_NAME}}", with: data.clientName)
        template = template.replacingOccurrences(of: "{{CLIENT_ADDRESS_LINE_1}}", with: data.clientAddress1)
        template = template.replacingOccurrences(of: "{{CLIENT_ADDRESS_LINE_2}}", with: data.clientAddress2 ?? "")
        template = template.replacingOccurrences(of: "{{CLIENT_EMAIL}}", with: data.clientEmail ?? "")
        template = template.replacingOccurrences(of: "{{CLIENT_PHONE}}", with: data.clientPhone ?? "")
        
        // Replace financial totals
        template = template.replacingOccurrences(of: "{{SUBTOTAL}}", with: data.subtotal)
        template = template.replacingOccurrences(of: "{{TAX_RATE}}", with: data.taxRate ?? "0")
        template = template.replacingOccurrences(of: "{{TAX_AMOUNT}}", with: data.taxAmount ?? "$0.00")
        template = template.replacingOccurrences(of: "{{DISCOUNT_AMOUNT}}", with: data.discountAmount ?? "$0.00")
        template = template.replacingOccurrences(of: "{{TOTAL_AMOUNT}}", with: data.totalAmount)
        template = template.replacingOccurrences(of: "{{AMOUNT_PAID}}", with: data.amountPaid ?? "$0.00")
        template = template.replacingOccurrences(of: "{{BALANCE_DUE}}", with: data.balanceDue)
        
        // Replace additional content
        template = template.replacingOccurrences(of: "{{NOTES}}", with: data.notes ?? "")
        template = template.replacingOccurrences(of: "{{TERMS}}", with: data.terms ?? "")
        template = template.replacingOccurrences(of: "{{FOOTER_TEXT}}", with: data.footerText ?? "")
        
        // Handle items array
        let itemsHTML = generateItemsHTML(items: data.items)
        template = template.replacingOccurrences(of: "{{#ITEMS}}[\\s\\S]*?{{/ITEMS}}", 
                                               with: itemsHTML, 
                                               options: .regularExpression)
        
        // Apply theme
        template = template.replacingOccurrences(of: "blue-theme", with: theme.cssClass)
        
        return template
    }
    
    private func generateItemsHTML(items: [InvoiceItem]) -> String {
        return items.map { item in
            """
            <tr class="item-row">
                <td class="item-description-cell">
                    <div class="item-name">\(item.name)</div>
                    <div class="item-description-text">\(item.description ?? "")</div>
                </td>
                <td class="item-quantity-cell">\(item.quantity)</td>
                <td class="item-rate-cell">\(item.rate)</td>
                <td class="item-amount-cell">\(item.amount)</td>
            </tr>
            """
        }.joined()
    }
}

enum InvoiceTheme: String, CaseIterable {
    case blue = "blue-theme"
    case green = "green-theme"
    case purple = "purple-theme"
    case black = "black-theme"
    
    var cssClass: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .black: return "Black"
        }
    }
}
```

### 3. WebKit PDF Generator

```swift
import WebKit
import UIKit
import PDFKit

class InvoicePDFGenerator: NSObject, ObservableObject {
    @Published var isGenerating = false
    @Published var generatedPDF: PDFDocument?
    
    private var webView: WKWebView?
    private var completion: ((Result<PDFDocument, Error>) -> Void)?
    
    override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842), // A4 size in points
                           configuration: configuration)
        webView?.navigationDelegate = self
    }
    
    func generatePDF(from invoiceData: InvoiceData, theme: InvoiceTheme = .blue) {
        guard let htmlContent = InvoiceTemplateManager.shared.populateTemplate(with: invoiceData, theme: theme) else {
            return
        }
        
        isGenerating = true
        
        // Load CSS file
        guard let cssPath = Bundle.main.path(forResource: "invoice-styles", ofType: "css"),
              let cssContent = try? String(contentsOfFile: cssPath) else {
            isGenerating = false
            return
        }
        
        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
            \(cssContent)
            </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        
        webView?.loadHTMLString(fullHTML, baseURL: Bundle.main.bundleURL)
    }
    
    private func createPDF() {
        guard let webView = webView else { return }
        
        let pdfConfiguration = WKPDFConfiguration()
        pdfConfiguration.rect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        
        webView.createPDF(configuration: pdfConfiguration) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                
                switch result {
                case .success(let data):
                    if let pdfDoc = PDFDocument(data: data) {
                        self?.generatedPDF = pdfDoc
                        self?.completion?(.success(pdfDoc))
                    }
                case .failure(let error):
                    self?.completion?(.failure(error))
                }
            }
        }
    }
    
    func generatePDF(from invoiceData: InvoiceData, 
                    theme: InvoiceTheme = .blue,
                    completion: @escaping (Result<PDFDocument, Error>) -> Void) {
        self.completion = completion
        generatePDF(from: invoiceData, theme: theme)
    }
}

extension InvoicePDFGenerator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait a bit for content to render, then create PDF
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createPDF()
        }
    }
}
```

### 4. SwiftUI Views

```swift
import SwiftUI
import PDFKit

struct InvoiceGeneratorView: View {
    @StateObject private var pdfGenerator = InvoicePDFGenerator()
    @State private var invoiceData = InvoiceData.sample
    @State private var selectedTheme: InvoiceTheme = .blue
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Theme Selector
                VStack(alignment: .leading) {
                    Text("Select Theme")
                        .font(.headline)
                    
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(InvoiceTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Invoice Preview
                InvoicePreviewView(invoiceData: invoiceData, theme: selectedTheme)
                
                Spacer()
                
                // Generate PDF Button
                Button(action: generatePDF) {
                    HStack {
                        if pdfGenerator.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(pdfGenerator.isGenerating ? "Generating PDF..." : "Generate PDF")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(pdfGenerator.isGenerating)
            }
            .padding()
            .navigationTitle("Invoice Generator")
            .sheet(isPresented: $showingPDFPreview) {
                if let pdf = pdfGenerator.generatedPDF {
                    PDFPreviewView(pdfDocument: pdf)
                }
            }
        }
    }
    
    private func generatePDF() {
        pdfGenerator.generatePDF(from: invoiceData, theme: selectedTheme) { result in
            switch result {
            case .success(_):
                showingPDFPreview = true
            case .failure(let error):
                print("PDF generation failed: \(error)")
            }
        }
    }
}

struct InvoicePreviewView: View {
    let invoiceData: InvoiceData
    let theme: InvoiceTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(invoiceData.companyName)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let tagline = invoiceData.companyTagline {
                        Text(tagline)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("INVOICE")
                        .font(.title)
                        .fontWeight(.light)
                    Text("#\(invoiceData.invoiceNumber)")
                        .font(.caption)
                }
            }
            
            Divider()
            
            // Client Info
            HStack {
                VStack(alignment: .leading) {
                    Text("BILL TO")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(invoiceData.clientName)
                        .fontWeight(.semibold)
                    Text(invoiceData.clientAddress1)
                        .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Amount Due")
                        .font(.caption)
                    Text(invoiceData.balanceDue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeColor)
                }
            }
            
            // Items Preview
            Text("Items (\(invoiceData.items.count))")
                .font(.caption)
                .fontWeight(.semibold)
            
            ForEach(invoiceData.items.prefix(3)) { item in
                HStack {
                    Text(item.name)
                        .font(.caption)
                    Spacer()
                    Text(item.amount)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if invoiceData.items.count > 3 {
                Text("... and \(invoiceData.items.count - 3) more items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var themeColor: Color {
        switch theme {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .black: return .black
        }
    }
}

struct PDFPreviewView: View {
    let pdfDocument: PDFDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfDocument: pdfDocument)
                .navigationTitle("Invoice Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Share") {
                            sharePDF()
                        }
                    }
                }
        }
    }
    
    private func sharePDF() {
        guard let data = pdfDocument.dataRepresentation() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [data],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}
```

### 5. Sample Data Extension

```swift
extension InvoiceData {
    static let sample = InvoiceData(
        companyName: "Sage Financials",
        companyTagline: "Financial Consulting Services",
        companyLogo: nil,
        companyAddress1: "123 Business District",
        companyAddress2: "New York, NY 10001",
        companyPhone: "+1 (555) 123-4567",
        companyEmail: "billing@sagefinancials.com",
        companyWebsite: "www.sagefinancials.com",
        invoiceNumber: "INV-001",
        invoiceDate: "March 15, 2024",
        dueDate: "April 14, 2024",
        paymentTerms: "NET-30",
        poNumber: "PO-2024-001",
        currency: "USD",
        clientName: "David Johnson",
        clientAddress1: "456 Client Street",
        clientAddress2: "Brooklyn, NY 11201",
        clientEmail: "david@mooninc.com",
        clientPhone: "+1 (555) 987-6543",
        items: [
            InvoiceItem(name: "Tax Consultation", 
                       description: "Comprehensive tax planning", 
                       quantity: "12", rate: "$150.00", amount: "$1,800.00"),
            InvoiceItem(name: "Business Plan", 
                       description: "Strategic business planning", 
                       quantity: "1", rate: "$500.00", amount: "$500.00"),
            InvoiceItem(name: "Financial Projections", 
                       description: "5-year financial forecasting", 
                       quantity: "10", rate: "$200.00", amount: "$2,000.00")
        ],
        subtotal: "$4,300.00",
        taxRate: "8.25",
        taxAmount: "$354.75",
        discountAmount: nil,
        totalAmount: "$4,654.75",
        amountPaid: "$1,000.00",
        balanceDue: "$3,654.75",
        notes: "Thank you for your business!",
        terms: "Payment due within 30 days.",
        footerText: "Generated electronically"
    )
}
```

## Setup Instructions

### 1. Add Files to Xcode Project
1. Add `invoice-template.html` and `invoice-styles.css` to your Xcode project bundle
2. Make sure they're included in your target's "Copy Bundle Resources"

### 2. Add Required Frameworks
```swift
import WebKit
import PDFKit
import UIKit
```

### 3. Permissions (if sharing PDFs)
Add to Info.plist:
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save invoice PDFs to Photos</string>
```

## Alternative Approaches

### Approach 2: Pure SwiftUI (No HTML)
- Create native SwiftUI views that replicate the invoice design
- Use `@ViewBuilder` for dynamic content
- Convert to PDF using `ImageRenderer` (iOS 16+)

### Approach 3: Server-Side Generation
- Send invoice data to your backend
- Generate PDF server-side using the HTML template
- Download and display in SwiftUI

## Benefits of WebKit Approach

✅ **Pixel-perfect** - Uses the exact same HTML/CSS template
✅ **Consistent** - Same output across web and mobile
✅ **Flexible** - Easy to update template without app changes
✅ **Professional** - Leverages web technologies for complex layouts
✅ **Theme support** - Multiple color schemes built-in

This approach gives you a professional invoice generator that maintains consistency with your web template while providing a native SwiftUI experience!

