//
//  InvoiceListViewModel.swift
//  invoice maker 2
//
//  ViewModel for managing invoice list on home screen
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class InvoiceListViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var searchText = ""
    @Published var selectedStatus: InvoiceStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadInvoices()
    }
    
    // Filtered invoices based on search and status
    var filteredInvoices: [Invoice] {
        var filtered = invoices
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { invoice in
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                invoice.clientName.localizedCaseInsensitiveContains(searchText) ||
                invoice.companyName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Sort by date (newest first)
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Recent invoices for dashboard
    var recentInvoices: [Invoice] {
        return Array(invoices
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5))
    }
    
    // Statistics
    var totalPending: Decimal {
        invoices
            .filter { $0.status == .sent || $0.status == .overdue }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalPaid: Decimal {
        invoices
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    func loadInvoices() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<Invoice>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            invoices = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load invoices: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteInvoice(_ invoice: Invoice) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(invoice)
        
        do {
            try modelContext.save()
            if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
                invoices.remove(at: index)
            }
        } catch {
            errorMessage = "Failed to delete invoice: \(error.localizedDescription)"
        }
    }
    
    func deleteInvoices(at offsets: IndexSet) {
        for index in offsets {
            if index < filteredInvoices.count {
                deleteInvoice(filteredInvoices[index])
            }
        }
    }
    
    func updateInvoiceStatus(_ invoice: Invoice, status: InvoiceStatus) {
        guard let modelContext = modelContext else { return }
        
        invoice.status = status
        invoice.updatedAt = Date()
        
        do {
            try modelContext.save()
            loadInvoices() // Reload to reflect changes
        } catch {
            errorMessage = "Failed to update invoice status: \(error.localizedDescription)"
        }
    }
    
    func duplicateInvoice(_ invoice: Invoice) -> Invoice? {
        guard let modelContext = modelContext else { return nil }
        
        let newInvoice = Invoice()
        
        // Copy all fields except ID and dates
        newInvoice.companyName = invoice.companyName
        newInvoice.companyAddress = invoice.companyAddress
        newInvoice.companyCity = invoice.companyCity
        newInvoice.companyPhone = invoice.companyPhone
        newInvoice.companyEmail = invoice.companyEmail
        
        newInvoice.clientName = invoice.clientName
        newInvoice.clientAddress = invoice.clientAddress
        newInvoice.clientCity = invoice.clientCity
        newInvoice.clientEmail = invoice.clientEmail
        
        newInvoice.taxRate = invoice.taxRate
        newInvoice.paymentTerms = invoice.paymentTerms
        newInvoice.notes = invoice.notes
        
        // Copy items
        for item in invoice.items {
            let newItem = InvoiceItem(
                name: item.name,
                description: item.itemDescription,
                quantity: item.quantity,
                rate: item.rate
            )
            newInvoice.items.append(newItem)
        }
        
        // Generate new invoice number
        newInvoice.invoiceNumber = generateInvoiceNumber()
        newInvoice.invoiceDate = Date()
        newInvoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        newInvoice.status = .draft
        
        // Calculate totals
        newInvoice.calculateTotals()
        
        // Save
        modelContext.insert(newInvoice)
        
        do {
            try modelContext.save()
            loadInvoices()
            return newInvoice
        } catch {
            errorMessage = "Failed to duplicate invoice: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func generateInvoiceNumber() -> String {
        let lastNumber = UserDefaults.standard.integer(forKey: "lastInvoiceNumber")
        let newNumber = lastNumber + 1
        UserDefaults.standard.set(newNumber, forKey: "lastInvoiceNumber")
        return String(format: "INV-%04d", newNumber)
    }
}