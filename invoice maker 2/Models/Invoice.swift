//
//  Invoice.swift
//  invoice maker 2
//
//  SwiftData model for Invoice with MVVM architecture
//

import Foundation
import SwiftData

@Model
final class Invoice {
    var id: UUID = UUID()
    var invoiceNumber: String = ""
    var invoiceDate: Date = Date()
    var dueDate: Date = Date()
    
    // Company Information (Optional fields)
    var companyName: String = ""
    var companyAddress: String?
    var companyCity: String?
    var companyPhone: String?
    var companyEmail: String?
    
    // Client Information (Optional fields)
    var clientName: String = ""
    var clientAddress: String?
    var clientCity: String?
    var clientEmail: String?
    
    // Financial
    var subtotal: Decimal = 0
    var taxRate: Decimal = 0
    var taxAmount: Decimal = 0
    var totalAmount: Decimal = 0
    
    // Additional
    var notes: String?
    var status: InvoiceStatus = InvoiceStatus.draft
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var items: [InvoiceItem] = []
    
    init() {
        self.id = UUID()
        self.invoiceNumber = ""
        self.invoiceDate = Date()
        self.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed properties for display
    var formattedInvoiceDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: invoiceDate)
    }
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: dueDate)
    }
    
    var formattedSubtotal: String {
        return formatCurrency(subtotal)
    }
    
    var formattedTaxAmount: String {
        return formatCurrency(taxAmount)
    }
    
    var formattedTotal: String {
        return formatCurrency(totalAmount)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }
    
    // Calculate totals
    func calculateTotals() {
        subtotal = items.reduce(0) { $0 + $1.amount }
        taxAmount = subtotal * (taxRate / 100)
        totalAmount = subtotal + taxAmount
        updatedAt = Date()
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .draft: return "purple"
        case .sent: return "blue"
        case .paid: return "green"
        case .overdue: return "red"
        case .cancelled: return "orange"
        }
    }
}

@Model
final class InvoiceItem {
    var id: UUID = UUID()
    var name: String = ""
    var itemDescription: String = ""
    var quantity: Decimal = 1
    var rate: Decimal = 0
    var amount: Decimal = 0
    
    init(name: String = "", description: String = "", quantity: Decimal = 1, rate: Decimal = 0) {
        self.id = UUID()
        self.name = name
        self.itemDescription = description
        self.quantity = quantity
        self.rate = rate
        self.amount = quantity * rate
    }
    
    func calculateAmount() {
        amount = quantity * rate
    }
    
    var formattedRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: rate as NSNumber) ?? "$0.00"
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }
    
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: quantity as NSNumber) ?? "0"
    }
}