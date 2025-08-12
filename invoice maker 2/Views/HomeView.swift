//
//  HomeView.swift
//  invoice maker 2
//
//  Home screen with invoice list and create button
//

import SwiftUI
import SwiftData
import PDFKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = InvoiceListViewModel()
    @State private var showingCreateInvoice = false
    @State private var selectedInvoice: Invoice?
    @State private var showingInvoiceDetail = false
    @State private var invoiceToView: Invoice?
    @State private var generatedPDFForViewing: PDFDocument?
    @State private var isGeneratingPDFForView = false
    @StateObject private var pdfGenerator = SimplePDFGenerator()
    // Cache for generated PDFs to avoid regeneration
    @State private var pdfCache: [UUID: PDFDocument] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                if viewModel.invoices.isEmpty && viewModel.searchText.isEmpty {
                    EmptyStateView()
                } else {
                    InvoiceListContent(
                        viewModel: viewModel,
                        selectedInvoice: $selectedInvoice,
                        showingInvoiceDetail: $showingInvoiceDetail,
                        invoiceToView: $invoiceToView,
                        onInvoiceTap: { invoice in
                            generatePDFForViewing(invoice: invoice)
                        }
                    )
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CreateInvoiceButton(showingCreateInvoice: $showingCreateInvoice)
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Invoices")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(InvoiceStatus.allCases, id: \.self) { status in
                            Button(action: {
                                if viewModel.selectedStatus == status {
                                    viewModel.selectedStatus = nil
                                } else {
                                    viewModel.selectedStatus = status
                                }
                            }) {
                                Label(
                                    status.rawValue,
                                    systemImage: viewModel.selectedStatus == status ? "checkmark.circle.fill" : "circle"
                                )
                            }
                        }
                        
                        Divider()
                        
                        Button("Clear Filter") {
                            viewModel.selectedStatus = nil
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search invoices")
            .refreshable {
                viewModel.loadInvoices()
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .sheet(isPresented: $showingCreateInvoice) {
            InvoiceFormView(invoice: nil)
                .onDisappear {
                    // Refresh invoice list when form is dismissed
                    viewModel.loadInvoices()
                }
        }
        .sheet(item: $selectedInvoice) { invoice in
            InvoiceFormView(invoice: invoice)
                .onDisappear {
                    // Clear cached PDF for edited invoice and refresh list
                    pdfCache.removeValue(forKey: invoice.id)
                    viewModel.loadInvoices()
                }
        }
        .sheet(item: $invoiceToView) { invoice in
            if let pdf = generatedPDFForViewing {
                PDFPreviewView(pdfDocument: pdf, invoice: invoice, onDismiss: nil)
            } else {
                ProgressView("Generating PDF...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
    }
    
    private func generatePDFForViewing(invoice: Invoice) {
        // Check if PDF is already cached
        if let cachedPDF = pdfCache[invoice.id] {
            generatedPDFForViewing = cachedPDF
            invoiceToView = invoice // Show the sheet immediately with cached PDF
            return
        }
        
        // Generate new PDF if not cached
        isGeneratingPDFForView = true
        generatedPDFForViewing = nil
        invoiceToView = invoice // Show the sheet with loading state
        
        // Convert invoice to old format for PDF generation
        let invoiceData = convertToInvoiceData(invoice: invoice)
        
        pdfGenerator.generatePDF(from: invoiceData) { [self] pdf in
            DispatchQueue.main.async {
                self.isGeneratingPDFForView = false
                
                if let pdf = pdf {
                    self.generatedPDFForViewing = pdf
                    self.pdfCache[invoice.id] = pdf // Cache the generated PDF
                }
            }
        }
    }
    
    private func convertToInvoiceData(invoice: Invoice) -> InvoiceData {
        var data = InvoiceData()
        
        // Company info
        data.companyName = invoice.companyName
        data.companyAddress = invoice.companyAddress ?? ""
        data.companyCity = invoice.companyCity ?? ""
        data.companyPhone = invoice.companyPhone ?? ""
        data.companyEmail = invoice.companyEmail ?? ""
        
        // Client info
        data.clientName = invoice.clientName
        data.clientAddress = invoice.clientAddress ?? ""
        data.clientCity = invoice.clientCity ?? ""
        data.clientEmail = invoice.clientEmail ?? ""
        
        // Invoice details
        data.invoiceNumber = invoice.invoiceNumber
        data.invoiceDate = invoice.formattedInvoiceDate
        data.dueDate = invoice.formattedDueDate
        data.paymentTerms = invoice.paymentTerms
        
        // Financial
        data.subtotal = invoice.formattedSubtotal
        data.taxRate = String(format: "%.2f", NSDecimalNumber(decimal: invoice.taxRate).doubleValue)
        data.taxAmount = invoice.formattedTaxAmount
        data.total = invoice.formattedTotal
        data.notes = invoice.notes ?? ""
        
        // Items
        data.items = invoice.items.map { item in
            OldInvoiceItem(
                name: item.name,
                description: item.itemDescription,
                quantity: item.formattedQuantity,
                rate: item.formattedRate,
                amount: item.formattedAmount
            )
        }
        
        return data
    }
}

// Empty state view
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Invoices Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first invoice to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Invoice list content
struct InvoiceListContent: View {
    @ObservedObject var viewModel: InvoiceListViewModel
    @Binding var selectedInvoice: Invoice?
    @Binding var showingInvoiceDetail: Bool
    @Binding var invoiceToView: Invoice?
    let onInvoiceTap: (Invoice) -> Void
    
    var body: some View {
        List {
            ForEach(viewModel.filteredInvoices) { invoice in
                InvoiceCardView(
                    invoice: invoice,
                    onTap: { onInvoiceTap(invoice) },
                    onEdit: { selectedInvoice = invoice },
                    onDelete: { viewModel.deleteInvoice(invoice) },
                    onDuplicate: { _ = viewModel.duplicateInvoice(invoice) },
                    onStatusChange: { status in viewModel.updateInvoiceStatus(invoice, status: status) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteInvoice(invoice)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        selectedInvoice = invoice
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                                         .tint(StatusColors.sent.color)
                    
                    Button {
                        _ = viewModel.duplicateInvoice(invoice)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .tint(.purple)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteInvoice(viewModel.filteredInvoices[index])
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}


// Invoice card view with new styling
struct InvoiceCardView: View {
    let invoice: Invoice
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onStatusChange: (InvoiceStatus) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Status stripe
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(statusColor.opacity(0.6))
                    .frame(width: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(statusColor.opacity(0.8), lineWidth: 0.5)
                    )
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 0) {
                            HStack(spacing: 12) {
                                Text(invoice.invoiceNumber)
                                    .font(.system(size: 17, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(.primary)
                                    .layoutPriority(1)
                                
                                StatusPill(status: invoice.status)
                                    .fixedSize()
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 6) {
                            Text(invoice.clientName)
                            Text("•")
                            Text(invoice.formattedInvoiceDate)
                        }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(invoice.formattedTotal)
                            .font(.system(size: 21, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(invoice.status == .overdue ? StatusColors.overdue.color : .primary)
                        
                        if invoice.status == .overdue {
                            Text("Due: \(invoice.formattedDueDate)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(StatusColors.overdue.color)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 80) // Ensure consistent card height
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(StatusColors.sent.color.opacity(0.12), lineWidth: isPressed ? 2 : 0)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Menu {
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    Button {
                        onStatusChange(status)
                    } label: {
                        Label(status.rawValue, systemImage: "circle.fill")
                    }
                }
            } label: {
                Label("Change Status", systemImage: "flag")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft: return StatusColors.draft.color
        case .sent: return StatusColors.sent.color
        case .paid: return StatusColors.paid.color
        case .overdue: return StatusColors.overdue.color
        case .cancelled: return StatusColors.cancelled.color
        }
    }
}

// Status pill
struct StatusPill: View {
    let status: InvoiceStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .medium))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(height: 22)
            .background(statusColor.fill)
            .foregroundColor(statusColor.color)
            .clipShape(Capsule())
    }
    
    private var statusColor: StatusColors {
        switch status {
        case .draft: return StatusColors.draft
        case .sent: return StatusColors.sent
        case .paid: return StatusColors.paid
        case .overdue: return StatusColors.overdue
        case .cancelled: return StatusColors.cancelled
        }
    }
}

// Create invoice button
struct CreateInvoiceButton: View {
    @Binding var showingCreateInvoice: Bool
    
    var body: some View {
        Button(action: {
            showingCreateInvoice = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [StatusColors.sent.color, StatusColors.sent.color.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        }
    }
}

// MARK: - Shared Colors
private enum HomeViewColors {
    static let accent: Color = Color(red: 0x25/255.0, green: 0x63/255.0, blue: 0xEB/255.0) // #2563EB
}

// MARK: - Status Colors (soft + accessible)
private enum StatusColors {
    case draft, sent, paid, cancelled, overdue
    
    var color: Color {
        switch self {
        case .draft: return Color(hex: "#9CA3AF")
        case .sent: return Color(hex: "#2563EB")
        case .paid: return Color(hex: "#16A34A")
        case .cancelled: return Color(hex: "#F59E0B")
        case .overdue: return Color(hex: "#EF4444")
        }
    }
    
    var fill: Color {
        switch self {
        case .draft: return Color(hex: "#9CA3AF").opacity(0.08)
        case .sent: return Color(hex: "#2563EB").opacity(0.08)
        case .paid: return Color(hex: "#16A34A").opacity(0.08)
        case .cancelled: return Color(hex: "#F59E0B").opacity(0.08)
        case .overdue: return Color(hex: "#EF4444").opacity(0.08)
        }
    }
}

private extension Color {
    init(hex: String) {
        let r, g, b, a: Double
        var hexString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        if hexString.count == 6 { hexString.append("FF") }

        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xFF000000) >> 24) / 255
            g = Double((hexNumber & 0x00FF0000) >> 16) / 255
            b = Double((hexNumber & 0x0000FF00) >> 8) / 255
            a = Double(hexNumber & 0x000000FF) / 255
        } else {
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Invoice.self, inMemory: true)
}