//
//  InvoiceDetailView.swift
//  invoice maker 2
//
//  Detail view to display invoice PDF template
//

import SwiftUI
import PDFKit

struct InvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    @StateObject private var pdfGenerator = SimplePDFGenerator()
    @State private var generatedPDF: PDFDocument?
    @State private var isGeneratingPDF = false
    @State private var showingEditInvoice = false
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let pdf = generatedPDF {
                    // PDF Display
                    PDFKitView(pdfDocument: pdf)
                } else if isGeneratingPDF {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating PDF...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Error state
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Unable to generate PDF")
                            .font(.headline)
                        
                        Text(errorMessage ?? "Unknown error occurred")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                
                // Action buttons at bottom
                if generatedPDF != nil {
                    HStack(spacing: 16) {
                        // Edit Button
                        Button(action: {
                            showingEditInvoice = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        // Share Button
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Invoice #\(invoice.invoiceNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                // Status bar at the top
                HStack {
                    Label(invoice.status.rawValue, systemImage: statusIcon(for: invoice.status))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(statusColor(for: invoice.status)))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(statusColor(for: invoice.status)).opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditInvoice = true
                        } label: {
                            Label("Edit Invoice", systemImage: "pencil")
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button {
                            generatePDF()
                        } label: {
                            Label("Refresh PDF", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            generatePDF()
        }
        .sheet(isPresented: $showingEditInvoice) {
            InvoiceFormView(invoice: invoice)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdf = generatedPDF {
                ShareSheet(pdfDocument: pdf, invoice: invoice)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func generatePDF() {
        isGeneratingPDF = true
        errorMessage = nil
        
        // Convert invoice to old format for PDF generation
        let invoiceData = convertToInvoiceData()
        
        pdfGenerator.generatePDF(from: invoiceData) { [self] pdf in
            DispatchQueue.main.async {
                self.isGeneratingPDF = false
                
                if let pdf = pdf {
                    self.generatedPDF = pdf
                } else {
                    self.errorMessage = "Failed to generate PDF. Please try again."
                }
            }
        }
    }
    
    private func convertToInvoiceData() -> InvoiceData {
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

// MARK: - Helper Functions
private func statusIcon(for status: InvoiceStatus) -> String {
    switch status {
    case .draft:
        return "doc.text"
    case .sent:
        return "paperplane"
    case .paid:
        return "checkmark.circle.fill"
    case .overdue:
        return "exclamationmark.triangle"
    case .cancelled:
        return "xmark.circle"
    }
}

private func statusColor(for status: InvoiceStatus) -> String {
    return status.color
}

#Preview {
    InvoiceDetailView(invoice: Invoice())
}