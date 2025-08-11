# PDF Generation Solution for iOS Invoice App

## Overview
This document describes the complete solution for generating multi-page PDF invoices in the iOS app with proper letter-size pagination.

## Problem Solved
- PDFs were generating as single long pages instead of multiple letter-sized pages
- Content was not properly paginating when it exceeded one page
- PDF viewer was zoomed in too much initially
- Share functionality needed proper file handling

## Solution Components

### 1. WebView Configuration
```swift
private func setupWebView() {
    let config = WKWebViewConfiguration()
    config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    
    // Extended height (5000) allows all content to render
    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 5000), configuration: config)
    webView?.navigationDelegate = self
    webView?.scrollView.isScrollEnabled = true
}
```

### 2. Custom Print Page Renderer
The key to multi-page PDFs is using a custom `UIPrintPageRenderer`:

```swift
class CustomPrintPageRenderer: UIPrintPageRenderer {
    func generatePDFData() -> Data {
        let pdfData = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        self.prepare(forDrawingPages: NSRange(location: 0, length: self.numberOfPages))
        
        let bounds = UIGraphicsGetPDFContextBounds()
        
        for pageIndex in 0..<self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: pageIndex, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}
```

### 3. PDF Generation Method
```swift
private func createPaginatedPDF(from webView: WKWebView) {
    let renderer = CustomPrintPageRenderer()
    let printFormatter = webView.viewPrintFormatter()
    
    renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
    
    // Letter size: 8.5" x 11" at 72 DPI
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let printableRect = CGRect(x: 36, y: 36, width: 540, height: 720)
    
    renderer.setValue(pageRect, forKey: "paperRect") 
    renderer.setValue(printableRect, forKey: "printableRect")
    
    let pdfData = renderer.generatePDFData()
    // Convert to PDFDocument...
}
```

### 4. PDF Viewer Configuration
Proper display settings for multi-page PDFs:

```swift
struct PDFViewer: UIViewRepresentable {
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        
        // Continuous scrolling for all pages
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        
        // Auto-scale to fit width
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        
        // Zoom limits
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 4.0
        
        return pdfView
    }
}
```

### 5. Share Functionality
Proper file handling for sharing PDFs:

```swift
private func sharePDF(_ pdf: PDFDocument) {
    guard let data = pdf.dataRepresentation() else { return }
    
    // Create temporary file with proper name
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("Invoice_\(invoiceNumber).pdf")
    
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
    
    // Present from top-most view controller
    // ... presentation code
}
```

## CSS Configuration
Essential CSS for proper pagination:

```css
@page {
    size: 8.5in 11in;
    margin: 0.5in;
}

@media print {
    body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
}

/* Table configuration for multi-page */
.items-table {
    page-break-inside: auto;
    break-inside: auto;
}

.items-table thead {
    display: table-header-group; /* Repeat header on each page */
}

.item-row {
    page-break-inside: avoid;
    break-inside: avoid;
}
```

## Key Points

1. **WebView Height**: Must be tall enough (5000px) to render all content
2. **Print Renderer**: `UIPrintPageRenderer` handles pagination automatically
3. **Page Size**: Letter size is 612x792 points (8.5" x 11" at 72 DPI)
4. **PDF Viewer**: Use `.singlePageContinuous` mode for scrolling through pages
5. **Auto-scaling**: Set after document assignment for proper initial zoom
6. **Share**: Use temporary file with proper filename for better UX

## Testing

1. Add multiple items using "Add 10 Test Items" button
2. Generate PDF - should create multiple pages
3. PDF viewer should display at readable zoom level
4. Share should work with proper filename

## Troubleshooting

- If pages are blank: Check that print formatter is properly configured
- If only one page: Verify WebView height is sufficient and CSS page rules are correct
- If zoom is wrong: Ensure `autoScales` is set after document assignment
- If share fails: Check file permissions and temporary directory access