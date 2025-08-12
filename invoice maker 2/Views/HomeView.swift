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
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredInvoices) { invoice in
                    InvoiceCardView(
                        invoice: invoice,
                        onTap: { onInvoiceTap(invoice) },
                        onEdit: { selectedInvoice = invoice },
                        onDelete: { viewModel.deleteInvoice(invoice) },
                        onDuplicate: { _ = viewModel.duplicateInvoice(invoice) },
                        onStatusChange: { status in viewModel.updateInvoiceStatus(invoice, status: status) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100) // Space for FAB
        }
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
                Rectangle()
                    .fill(statusColor)
                    .frame(width: 4)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 0) {
                            HStack(spacing: 12) {
                                Text(invoice.invoiceNumber)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: true, vertical: false)
                                
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
                            .font(.system(size: 20, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        
                        if invoice.status == .overdue {
                            Text("Due: \(invoice.formattedDueDate)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
                .stroke(HomeViewColors.accent.opacity(0.15), lineWidth: isPressed ? 2 : 0)
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
        case .draft: return .gray
        case .sent: return HomeViewColors.accent
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .orange
        }
    }
}

// Status pill
struct StatusPill: View {
    let status: InvoiceStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 14, weight: .medium))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .sent: return HomeViewColors.accent
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .orange
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
                .background(HomeViewColors.accent)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        }
    }
}

// MARK: - Shared Colors
private enum HomeViewColors {
    static let accent: Color = Color(red: 0x25/255.0, green: 0x63/255.0, blue: 0xEB/255.0) // #2563EB
}

#Preview {
    HomeView()
        .modelContainer(for: Invoice.self, inMemory: true)
}