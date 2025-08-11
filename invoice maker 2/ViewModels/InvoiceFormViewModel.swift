//
//  InvoiceFormViewModel.swift
//  invoice maker 2
//
//  ViewModel for invoice creation and editing form
//

import Foundation
import SwiftData
import SwiftUI
import PDFKit

@MainActor
class InvoiceFormViewModel: ObservableObject {
    @Published var invoice: Invoice
    @Published var isEditing: Bool = false
    @Published var showingPDFPreview = false
    @Published var generatedPDF: PDFDocument?
    @Published var isGeneratingPDF = false
    @Published var errorMessage: String?
    
    // Form field bindings
    @Published var invoiceDate = Date()
    @Published var dueDate = Date()
    @Published var taxRateString = "0"
    
    private var modelContext: ModelContext?
    private let pdfGenerator = SimplePDFGenerator()
    
    init(invoice: Invoice? = nil) {
        if let invoice = invoice {
            self.invoice = invoice
            self.isEditing = true
            self.invoiceDate = invoice.invoiceDate
            self.dueDate = invoice.dueDate
            self.taxRateString = String(format: "%.2f", NSDecimalNumber(decimal: invoice.taxRate).doubleValue)
        } else {
            self.invoice = Invoice()
            self.setupNewInvoice()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupNewInvoice() {
        // Auto-generate invoice number
        invoice.invoiceNumber = generateInvoiceNumber()
        
        // Set dates
        invoice.invoiceDate = Date()
        invoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        invoiceDate = invoice.invoiceDate
        dueDate = invoice.dueDate
        
        // Load saved company info from UserDefaults if available
        loadSavedCompanyInfo()
        
        // Add a default item
        addNewItem()
    }
    
    private func generateInvoiceNumber() -> String {
        let lastNumber = UserDefaults.standard.integer(forKey: "lastInvoiceNumber")
        let newNumber = lastNumber + 1
        UserDefaults.standard.set(newNumber, forKey: "lastInvoiceNumber")
        return String(format: "INV-%04d", newNumber)
    }
    
    private func loadSavedCompanyInfo() {
        // Load company info from UserDefaults for quick reuse
        if let companyName = UserDefaults.standard.string(forKey: "companyName") {
            invoice.companyName = companyName
        }
        if let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") {
            invoice.companyAddress = companyAddress
        }
        if let companyCity = UserDefaults.standard.string(forKey: "companyCity") {
            invoice.companyCity = companyCity
        }
        if let companyPhone = UserDefaults.standard.string(forKey: "companyPhone") {
            invoice.companyPhone = companyPhone
        }
        if let companyEmail = UserDefaults.standard.string(forKey: "companyEmail") {
            invoice.companyEmail = companyEmail
        }
    }
    
    func saveCompanyInfo() {
        // Save company info to UserDefaults for future use
        UserDefaults.standard.set(invoice.companyName, forKey: "companyName")
        UserDefaults.standard.set(invoice.companyAddress, forKey: "companyAddress")
        UserDefaults.standard.set(invoice.companyCity, forKey: "companyCity")
        UserDefaults.standard.set(invoice.companyPhone, forKey: "companyPhone")
        UserDefaults.standard.set(invoice.companyEmail, forKey: "companyEmail")
    }
    
    // MARK: - Item Management
    
    func addNewItem() {
        let newItem = InvoiceItem()
        invoice.items.append(newItem)
        calculateTotals()
    }
    
    func deleteItem(at index: Int) {
        guard index < invoice.items.count else { return }
        invoice.items.remove(at: index)
        calculateTotals()
    }
    
    func updateItem(at index: Int) {
        guard index < invoice.items.count else { return }
        invoice.items[index].calculateAmount()
        calculateTotals()
    }
    
    // MARK: - Calculations
    
    func calculateTotals() {
        // Update tax rate from string
        if let taxRate = Decimal(string: taxRateString) {
            invoice.taxRate = taxRate
        }
        
        // Calculate totals
        invoice.calculateTotals()
    }
    
    // MARK: - Save Invoice
    
    func saveInvoice() -> Bool {
        guard let modelContext = modelContext else {
            errorMessage = "Database context not available"
            return false
        }
        
        // Validate required fields
        guard !invoice.companyName.isEmpty else {
            errorMessage = "Company name is required"
            return false
        }
        
        guard !invoice.clientName.isEmpty else {
            errorMessage = "Client name is required"
            return false
        }
        
        guard !invoice.items.isEmpty else {
            errorMessage = "At least one item is required"
            return false
        }
        
        // Update dates
        invoice.invoiceDate = invoiceDate
        invoice.dueDate = dueDate
        
        // Calculate final totals
        calculateTotals()
        
        // Save company info for future use
        saveCompanyInfo()
        
        // Set update timestamp
        invoice.updatedAt = Date()
        
        // Insert or update
        if !isEditing {
            modelContext.insert(invoice)
        }
        
        do {
            try modelContext.save()
            return true
        } catch {
            errorMessage = "Failed to save invoice: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - PDF Generation
    
    func generatePDF() {
        isGeneratingPDF = true
        errorMessage = nil
        
        // Convert to old InvoiceData format for PDF generation
        let invoiceData = convertToInvoiceData()
        
        pdfGenerator.generatePDF(from: invoiceData) { [weak self] pdf in
            DispatchQueue.main.async {
                self?.isGeneratingPDF = false
                
                if let pdf = pdf {
                    self?.generatedPDF = pdf
                    self?.showingPDFPreview = true
                } else {
                    self?.errorMessage = "Failed to generate PDF"
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
        data.paymentTerms = invoice.paymentTerms
        
        // Financial
        data.subtotal = invoice.formattedSubtotal
        data.taxRate = String(format: "%.2f", NSDecimalNumber(decimal: invoice.taxRate).doubleValue)
        data.taxAmount = invoice.formattedTaxAmount
        data.total = invoice.formattedTotal
        data.notes = invoice.notes ?? ""
        
        // Items (Convert to old format for PDF generation)
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
    
    // Payment terms options
    let paymentTermsOptions = [
        "Due on Receipt",
        "NET-7",
        "NET-15",
        "NET-30",
        "NET-45",
        "NET-60",
        "NET-90"
    ]
}