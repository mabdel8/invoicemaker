# Invoice Management System - MVVM Implementation

## Overview
Complete invoice management system built with SwiftUI, SwiftData, and MVVM architecture.

## Architecture Components

### 1. Models (SwiftData)
- **Invoice.swift**: Main invoice model with relationships
  - Auto-generated invoice numbers
  - Optional fields for company/client info
  - Status tracking (Draft, Sent, Paid, Overdue, Cancelled)
  - Automatic total calculations
  
- **InvoiceItem.swift**: Line items with quantity, rate, and amount calculations

### 2. ViewModels
- **InvoiceListViewModel**: 
  - Manages invoice list on home screen
  - Filtering by search and status
  - Statistics (total pending, total paid)
  - CRUD operations
  
- **InvoiceFormViewModel**:
  - Handles invoice creation/editing
  - Auto-generates invoice numbers
  - Saves company info to UserDefaults for reuse
  - PDF generation integration

### 3. Views
- **HomeView**: 
  - List of recent invoices
  - Search and filter functionality
  - Floating action button for new invoice
  - Swipe actions (edit, delete, duplicate)
  
- **InvoiceFormView**:
  - Company info (name required, others optional)
  - Client info (name required, others optional)
  - Dynamic invoice items
  - Auto-calculated totals
  - PDF preview generation
  
- **PDFPreviewView**:
  - Inline PDF thumbnail preview
  - Export to Files app
  - Share functionality
  - Full PDF viewer on tap

## Key Features

### 1. Auto-Generation
- Invoice numbers: `INV-0001`, `INV-0002`, etc.
- Current date for invoice date
- Due date: 30 days from invoice date
- Saved company info auto-fills

### 2. Optional Fields
**Company Info:**
- Name (required)
- Address, City, Phone, Email (optional)

**Client Info:**
- Name (required)
- Address, City, Email (optional)

### 3. PDF Generation Flow
1. Fill invoice form
2. Click "Generate PDF Preview"
3. See inline preview with invoice summary
4. Options:
   - Export (saves to Files app)
   - Share (opens share sheet)
   - View Full PDF (full-screen viewer)

### 4. Data Persistence
- SwiftData for invoice storage
- UserDefaults for company info
- Auto-incrementing invoice numbers

## User Flow

1. **Home Screen**
   - View list of invoices
   - Search/filter invoices
   - Tap (+) button to create new

2. **Create Invoice**
   - Auto-generated invoice number
   - Fill required fields (company/client name)
   - Add invoice items
   - Generate PDF preview

3. **PDF Preview**
   - See thumbnail preview
   - Export or share
   - Tap to view full PDF

4. **Invoice Management**
   - Edit existing invoices
   - Change status
   - Duplicate for similar invoices
   - Delete unwanted invoices

## Technical Implementation

### SwiftData Configuration
```swift
let schema = Schema([
    Invoice.self,
    InvoiceItem.self
])
```

### MVVM Pattern
- **Models**: Data structure and business logic
- **ViewModels**: @Published properties, business operations
- **Views**: SwiftUI declarative UI

### PDF Generation
- Uses existing `SimplePDFGenerator`
- Converts new models to legacy format for compatibility
- Multi-page support with proper pagination

## Testing the App

1. **Run the app** - HomeView appears with empty state
2. **Create invoice** - Tap (+) button
3. **Fill form** - Notice auto-generated invoice number
4. **Add items** - Dynamic item management
5. **Generate PDF** - See preview with export/share options
6. **Save invoice** - Returns to home with new invoice listed
7. **Edit invoice** - Swipe or tap to edit existing

## File Structure
```
invoice maker 2/
├── Models/
│   └── Invoice.swift
├── ViewModels/
│   ├── InvoiceListViewModel.swift
│   └── InvoiceFormViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── InvoiceFormView.swift
│   └── PDFPreviewView.swift
└── invoice_maker_2App.swift (entry point)
```

## Future Enhancements
- Cloud sync with iCloud
- Multiple templates
- Currency selection
- Tax presets
- Client database
- Invoice templates
- Export to accounting software
- Analytics dashboard