//
//  InvoiceFormView.swift
//  invoice maker 2
//
//  Invoice creation and editing form with optional fields
//

import SwiftUI
import Foundation
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CardSection(title: "Invoice Details") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Invoice Number")
                                    .rowLabelStyle()
                                Spacer()
                                Text(viewModel.invoice.invoiceNumber)
                                    .valueTextStyle()
                                    .monospacedDigit()
                            }

                            DatePicker("Invoice Date",
                                      selection: $viewModel.invoiceDate,
                                      displayedComponents: .date)
                            .transaction { $0.animation = nil }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.system(size: 17))
                            .monospacedDigit()
                            .rowContainerLabel("Invoice Date")

                            DatePicker("Due Date",
                                      selection: $viewModel.dueDate,
                                      displayedComponents: .date)
                            .transaction { $0.animation = nil }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.system(size: 17))
                            .monospacedDigit()
                            .rowContainerLabel("Due Date")

                            HStack {
                                Text("Payment Terms")
                                    .rowLabelStyle()
                                Spacer()
                                Menu {
                                    ForEach(viewModel.paymentTermsOptions, id: \.self) { term in
                                        Button(term) {
                                            viewModel.invoice.paymentTerms = term
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(viewModel.invoice.paymentTerms)
                                            .valueTextStyle()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Status")
                                    .rowLabelStyle()
                                Spacer()
                                Menu {
                                    ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                        Button(action: {
                                            viewModel.invoice.status = status
                                        }) {
                                            Label(status.rawValue, systemImage: statusIcon(for: status))
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(statusColor(for: viewModel.invoice.status)))
                                            .frame(width: 8, height: 8)
                                        Text(viewModel.invoice.status.rawValue)
                                            .valueTextStyle()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    CardSection(title: "Company Information") {
                        VStack(alignment: .leading, spacing: 12) {
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
                    }

                    CardSection(title: "Client Information") {
                        VStack(alignment: .leading, spacing: 12) {
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
                    }

                    CardSection(title: "Invoice Items") {
                        VStack(alignment: .leading, spacing: 12) {
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
                                HairlineDivider()
                            }
                            Button(action: {
                                withAnimation {
                                    viewModel.addNewItem()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Item")
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.accent.opacity(0.12))
                                .foregroundColor(AppColors.accent)
                                .cornerRadius(10)
                            }
                        }
                    }

                    CardSection(title: "Totals") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .rowLabelStyle()
                                Spacer()
                                Text(viewModel.invoice.formattedSubtotal)
                                    .valueTextStyle()
                            }

                            HStack {
                                Text("Tax Rate (%)")
                                    .rowLabelStyle()
                                Spacer()
                                TextField("0.00", text: $viewModel.taxRateString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .font(.system(size: 17))
                                    .monospacedDigit()
                                    .onChange(of: viewModel.taxRateString) { _ in
                                        viewModel.calculateTotals()
                                    }
                            }

                            HStack {
                                Text("Tax Amount")
                                    .rowLabelStyle()
                                Spacer()
                                Text(viewModel.invoice.formattedTaxAmount)
                                    .valueTextStyle()
                            }

                            HStack {
                                Text("Total")
                                    .rowLabelStyle()
                                Spacer()
                                Text(viewModel.invoice.formattedTotal)
                                    .valueTextStyle()
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }

                    CardSection(title: "Notes (Optional)") {
                        TextEditor(text: Binding(
                            get: { viewModel.invoice.notes ?? "" },
                            set: { viewModel.invoice.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppColors.background.ignoresSafeArea())
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
                                    .tint(AppColors.accent)
                            }
                            Text(viewModel.isGeneratingPDF ? "Generating..." : "Generate")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isGeneratingPDF)
                }
            }
            .tint(AppColors.accent)
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
                        .background(AppColors.accent.opacity(0.12))
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

// MARK: - Shared Styles

private struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // Subtle in-card header
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                HairlineDivider()

                content
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hairlineColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        }
    }

    private var hairlineColor: Color {
        if colorScheme == .dark {
            return Color(red: 0x2D/255.0, green: 0x2D/255.0, blue: 0x2F/255.0).opacity(0.25)
        } else {
            return Color(red: 0xE8/255.0, green: 0xE8/255.0, blue: 0xED/255.0)
        }
    }
}

private struct HairlineDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Rectangle()
            .fill(hairlineColor)
            .frame(height: 1)
            .padding(.horizontal, -8) // 8pt negative inset
    }

    private var hairlineColor: Color {
        if colorScheme == .dark {
            return Color(red: 0x2D/255.0, green: 0x2D/255.0, blue: 0x2F/255.0).opacity(0.25)
        } else {
            return Color(red: 0xE8/255.0, green: 0xE8/255.0, blue: 0xED/255.0)
        }
    }
}

private enum AppColors {
    static let accent: Color = Color(hex: "#2563EB")
    static let background: Color = Color(hex: "#F7F8FB")
}

// MARK: - Typography Helpers
private struct RowLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .kerning(-0.2/1000) // subtle tracking adjustment
            .foregroundColor(.secondary)
    }
}

private struct ValueTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.primary)
            .monospacedDigit()
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

// MARK: - Status Pill Component
private extension View {
    func rowLabelStyle() -> some View { modifier(RowLabelStyle()) }
    func valueTextStyle() -> some View { modifier(ValueTextStyle()) }

    // Helper to wrap a trailing control with a leading label matching our row style
    func rowContainerLabel(_ label: String) -> some View {
        HStack {
            Text(label).rowLabelStyle()
            Spacer()
            self
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
    InvoiceFormView()
        .modelContainer(for: Invoice.self, inMemory: true)
}