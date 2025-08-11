//
//  InvoiceFormView.swift
//  invoice maker 2
//
//  Invoice creation and editing form with optional fields
//

import SwiftUI
import SwiftData

struct InvoiceFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: InvoiceFormViewModel
    @State private var showingPDFPreview = false
    @State private var showingDiscardAlert = false
    
    init(invoice: Invoice? = nil) {
        _viewModel = StateObject(wrappedValue: InvoiceFormViewModel(invoice: invoice))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Invoice Details Section
                Section("Invoice Details") {
                    HStack {
                        Text("Invoice Number")
                        Spacer()
                        Text(viewModel.invoice.invoiceNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Invoice Date",
                              selection: $viewModel.invoiceDate,
                              displayedComponents: .date)
                    
                    DatePicker("Due Date",
                              selection: $viewModel.dueDate,
                              displayedComponents: .date)
                    
                    Picker("Payment Terms", selection: $viewModel.invoice.paymentTerms) {
                        ForEach(viewModel.paymentTermsOptions, id: \.self) { term in
                            Text(term).tag(term)
                        }
                    }
                }
                
                // Company Information Section
                Section("Company Information") {
                    TextField("Company Name *", text: $viewModel.invoice.companyName)
                        .textContentType(.organizationName)
                    
                    TextField("Address (Optional)", text: Binding(
                        get: { viewModel.invoice.companyAddress ?? "" },
                        set: { viewModel.invoice.companyAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.streetAddressLine1)
                    
                    TextField("City, State ZIP (Optional)", text: Binding(
                        get: { viewModel.invoice.companyCity ?? "" },
                        set: { viewModel.invoice.companyCity = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.addressCityAndState)
                    
                    TextField("Phone (Optional)", text: Binding(
                        get: { viewModel.invoice.companyPhone ?? "" },
                        set: { viewModel.invoice.companyPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    
                    TextField("Email (Optional)", text: Binding(
                        get: { viewModel.invoice.companyEmail ?? "" },
                        set: { viewModel.invoice.companyEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }
                
                // Client Information Section
                Section("Client Information") {
                    TextField("Client Name *", text: $viewModel.invoice.clientName)
                        .textContentType(.name)
                    
                    TextField("Address (Optional)", text: Binding(
                        get: { viewModel.invoice.clientAddress ?? "" },
                        set: { viewModel.invoice.clientAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.streetAddressLine1)
                    
                    TextField("City, State ZIP (Optional)", text: Binding(
                        get: { viewModel.invoice.clientCity ?? "" },
                        set: { viewModel.invoice.clientCity = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.addressCityAndState)
                    
                    TextField("Email (Optional)", text: Binding(
                        get: { viewModel.invoice.clientEmail ?? "" },
                        set: { viewModel.invoice.clientEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }
                
                // Invoice Items Section
                Section("Invoice Items") {
                    ForEach(viewModel.invoice.items) { item in
                        InvoiceItemRow(
                            item: item,
                            onUpdate: {
                                viewModel.calculateTotals()
                            },
                            onDelete: {
                                if let index = viewModel.invoice.items.firstIndex(where: { $0.id == item.id }) {
                                    viewModel.deleteItem(at: index)
                                }
                            },
                            viewModel: viewModel
                        )
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewModel.addNewItem()
                        }
                    }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Totals Section
                Section("Totals") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.invoice.formattedSubtotal)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("0.00", text: $viewModel.taxRateString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: viewModel.taxRateString) { _ in
                                viewModel.calculateTotals()
                            }
                    }
                    
                    HStack {
                        Text("Tax Amount")
                        Spacer()
                        Text(viewModel.invoice.formattedTaxAmount)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(viewModel.invoice.formattedTotal)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Notes Section
                Section("Notes (Optional)") {
                    TextEditor(text: Binding(
                        get: { viewModel.invoice.notes ?? "" },
                        set: { viewModel.invoice.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 60)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Invoice" : "New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDiscardAlert = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        generateInvoice()
                    }) {
                        HStack(spacing: 4) {
                            if viewModel.isGeneratingPDF {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.blue)
                            }
                            Text(viewModel.isGeneratingPDF ? "Generating..." : "Generate")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isGeneratingPDF)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("Are you sure you want to discard this invoice?")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showingPDFPreview) {
                if let pdf = viewModel.generatedPDF {
                    PDFPreviewView(
                        pdfDocument: pdf,
                        invoice: viewModel.invoice,
                        onDismiss: {
                            // Dismiss the invoice form when PDF preview is closed
                            dismiss()
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    private func generateInvoice() {
        viewModel.generateAndSaveInvoice()
        // Note: We don't dismiss immediately anymore since we want to show the PDF preview
        // The view will be dismissed when user closes the PDF preview or manually cancels
    }
}

// Invoice Item Row
struct InvoiceItemRow: View {
    let item: InvoiceItem
    let onUpdate: () -> Void
    let onDelete: () -> Void
    @ObservedObject var viewModel: InvoiceFormViewModel
    
    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
    @State private var quantityString: String = ""
    @State private var rateString: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Item \(item.name.isEmpty ? "(New)" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            TextField("Item Name", text: $itemName)
                .onChange(of: itemName) { newValue in
                    item.name = newValue
                    onUpdate()
                }
            
            TextField("Description", text: $itemDescription)
                .onChange(of: itemDescription) { newValue in
                    item.itemDescription = newValue
                    onUpdate()
                }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Qty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("1", text: $quantityString)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: quantityString) { newValue in
                            if let value = Decimal(string: newValue) {
                                item.quantity = value
                                item.calculateAmount()
                                onUpdate()
                            }
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("$0.00", text: $rateString)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: rateString) { newValue in
                            if let value = Decimal(string: newValue) {
                                item.rate = value
                                item.calculateAmount()
                                onUpdate()
                            }
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.formattedAmount)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            itemName = item.name
            itemDescription = item.itemDescription
            quantityString = String(format: "%.2f", NSDecimalNumber(decimal: item.quantity).doubleValue)
            rateString = String(format: "%.2f", NSDecimalNumber(decimal: item.rate).doubleValue)
        }
    }
}

#Preview {
    InvoiceFormView()
        .modelContainer(for: Invoice.self, inMemory: true)
}