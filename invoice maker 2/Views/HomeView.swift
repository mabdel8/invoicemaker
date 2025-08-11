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
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                            .padding()
                    }
                }
            }
            .navigationTitle("Invoices")
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
        }
        .sheet(item: $selectedInvoice) { invoice in
            InvoiceFormView(invoice: invoice)
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
        isGeneratingPDFForView = true
        generatedPDFForViewing = nil
        
        // Convert invoice to old format for PDF generation
        let invoiceData = convertToInvoiceData(invoice: invoice)
        
        pdfGenerator.generatePDF(from: invoiceData) { [self] pdf in
            DispatchQueue.main.async {
                self.isGeneratingPDFForView = false
                
                if let pdf = pdf {
                    self.generatedPDFForViewing = pdf
                    self.invoiceToView = invoice // Show the sheet
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
            // Invoices Section
            Section(header: Text("Invoices")) {
                ForEach(viewModel.filteredInvoices) { invoice in
                    InvoiceRowView(
                        invoice: invoice,
                        onTap: {
                            onInvoiceTap(invoice)
                        }
                    )
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
                        .tint(.blue)
                        
                        Button {
                            _ = viewModel.duplicateInvoice(invoice)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.purple)
                    }
                    .contextMenu {
                        Button {
                            selectedInvoice = invoice
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            _ = viewModel.duplicateInvoice(invoice)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        
                        Divider()
                        
                        Menu {
                            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                Button {
                                    viewModel.updateInvoiceStatus(invoice, status: status)
                                } label: {
                                    Label(status.rawValue, systemImage: "circle.fill")
                                }
                            }
                        } label: {
                            Label("Change Status", systemImage: "flag")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            viewModel.deleteInvoice(invoice)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteInvoices)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}


// Invoice row view
struct InvoiceRowView: View {
    let invoice: Invoice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(invoice.invoiceNumber)
                            .font(.headline)
                        
                        StatusBadge(status: invoice.status)
                    }
                    
                    Text(invoice.clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(invoice.formattedInvoiceDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(invoice.formattedTotal)
                        .font(.headline)
                    
                    if invoice.status == .overdue {
                        Text("Due: \(invoice.formattedDueDate)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Status badge
struct StatusBadge: View {
    let status: InvoiceStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .sent: return .blue
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
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Invoice.self, inMemory: true)
}