# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native iOS invoice generator app built with SwiftUI and SwiftData. The app creates professional PDF invoices using WebKit rendering with embedded HTML/CSS templates.

**Key Architecture**: The app combines SwiftUI for native iOS UI with HTML/CSS templates for consistent PDF rendering. It uses SwiftData for persistence and WebKit for HTML-to-PDF conversion.

## Development Commands

### Xcode Development
```bash
# Open Xcode project
open "invoice maker 2.xcodeproj"

# Build from command line (run from project root)
cd "invoice maker 2"
xcodebuild -scheme "invoice maker 2" -configuration Debug build

# Build for release
xcodebuild -scheme "invoice maker 2" -configuration Release build

# Clean build folder
xcodebuild -scheme "invoice maker 2" clean
```

### iOS Simulator Testing
Use Xcode's built-in simulator or:
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15"

# Install and run app (after building)
xcrun simctl install booted "path/to/app.app"
xcrun simctl launch booted com.yourcompany.invoice-maker-2
```

## Architecture Overview

### MVVM + SwiftData Architecture
The app follows MVVM pattern with SwiftData for persistence:

**Models (`Models/`)**:
- `Invoice.swift`: Main invoice data model with SwiftData persistence
- `InvoiceItem.swift`: Line items with automatic amount calculation

**Views (`Views/`)**:
- `HomeView.swift`: Main invoice list with search/filtering
- `InvoiceFormView.swift`: Create/edit invoice form
- `InvoiceDetailView.swift`: Invoice details display
- `PDFPreviewView.swift`: PDF viewer with sharing capabilities

**ViewModels (`ViewModels/`)**:
- `InvoiceListViewModel.swift`: Manages invoice list, search, filtering
- `InvoiceFormViewModel.swift`: Handles form validation and data management

### PDF Generation System
The app uses a hybrid HTML/WebKit approach:

1. **HTML Template**: Creates invoice HTML with embedded CSS styling
2. **WebKit Rendering**: Uses `WKWebView` to render HTML content
3. **PDF Creation**: Converts WebKit output to PDF using `UIPrintPageRenderer`
4. **Multi-page Support**: Handles automatic pagination with proper page breaks

**Critical Components**:
- `SimplePDFGenerator`: Core PDF generation class in `ContentView.swift`
- `CustomPrintPageRenderer`: Handles multi-page PDF creation
- Embedded CSS with `@page` rules for proper pagination

### Data Flow
1. User creates invoice → `InvoiceFormView` + `InvoiceFormViewModel`
2. Data saved → SwiftData persistence (`Invoice` + `InvoiceItem` models)
3. PDF generation → Convert SwiftData models to legacy `InvoiceData` format
4. HTML creation → Template population with invoice data
5. WebKit rendering → HTML to PDF conversion
6. Display/sharing → `PDFPreviewView` with native sharing

## Key Integration Points

### SwiftData to PDF Bridge
The app maintains two data formats:
- **Modern**: SwiftData models (`Invoice`, `InvoiceItem`) for persistence
- **Legacy**: `InvoiceData` struct for PDF generation compatibility

Conversion happens in `convertToInvoiceData()` method in `HomeView.swift`.

### WebKit PDF Generation
Located in `SimplePDFGenerator` class:
- Uses `WKWebView` with extended height (5000px) for full content rendering
- Custom `UIPrintPageRenderer` for proper multi-page PDF creation
- CSS `@page` rules ensure letter-size (8.5" x 11") pagination
- Page break handling prevents content duplication across pages

### App Entry Points
- `invoice_maker_2App.swift`: Main app with SwiftData container setup
- `HomeView.swift`: Primary navigation hub (replaces `ContentView` as main view)
- Model container configured for `Invoice` and `InvoiceItem` persistence

## File Organization

### Project Structure
```
invoice maker 2/
├── invoice maker 2.xcodeproj/     # Xcode project
└── invoice maker 2/               # Source code
    ├── Models/                    # SwiftData models
    │   └── Invoice.swift         
    ├── Views/                     # SwiftUI views
    │   ├── HomeView.swift        # Main invoice list
    │   ├── InvoiceFormView.swift # Create/edit form
    │   ├── InvoiceDetailView.swift
    │   └── PDFPreviewView.swift  # PDF viewer
    ├── ViewModels/               # MVVM view models
    │   ├── InvoiceListViewModel.swift
    │   └── InvoiceFormViewModel.swift
    ├── ContentView.swift         # PDF generation logic
    ├── invoice_maker_2App.swift  # App entry point
    ├── invoice-template.html     # PDF template
    └── invoice-styles.css        # PDF styling
```

### Legacy Files
- `Item.swift`: Original SwiftData model (unused, kept for reference)
- `ContentView.swift`: Contains PDF generation logic but not used as main view

## PDF Template System

### HTML Template (`invoice-template.html`)
Professional invoice template with variable placeholders. CSS embedded inline for WebKit compatibility.

### CSS Styling (`invoice-styles.css`)
- Letter-size page setup with proper margins
- Page break controls to prevent content duplication
- Professional styling with gradient headers
- Print-optimized fonts and spacing

### Variable Replacement
Template uses string interpolation in Swift rather than placeholder tokens, allowing for complex formatting and calculations within the HTML generation process.

## Testing & Debugging

### PDF Generation Testing
- Use "Add 10 Test Items" button in form to test multi-page PDFs
- Test various invoice sizes to ensure proper pagination
- Verify PDF quality on different iOS devices and screen sizes

### SwiftData Debugging
- Models use `@Model` macro for automatic SwiftData integration
- Relationships configured with cascade delete rules
- Check console for SwiftData persistence errors

## Common Development Tasks

### Adding New Invoice Fields
1. Update `Invoice` model with new property
2. Add form field in `InvoiceFormView`
3. Update `convertToInvoiceData()` in `HomeView`
4. Modify HTML template in `SimplePDFGenerator.createHTML()`

### Customizing PDF Appearance
1. Modify embedded CSS in `SimplePDFGenerator.createHTML()`
2. Test with various invoice sizes for pagination
3. Ensure print-friendly colors and fonts
4. Verify `@page` rules for proper letter-size output