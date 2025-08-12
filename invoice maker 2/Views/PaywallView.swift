//
//  PaywallView.swift
//  invoice maker 2
//
//  Modern paywall with subscription options
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProductID: String = "im_lifetime"
    @State private var isWeeklySelected = false
    @State private var isPurchasing = false
    @State private var showingError = false
    
    let isModal: Bool
    
    init(isModal: Bool = true) {
        self.isModal = isModal
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBlue).opacity(0.03),
                        Color(.systemPurple).opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            // Premium badge
                            HStack {
                                Spacer()
                                Text("PREMIUM")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                                Spacer()
                            }
                            
//                            Text("Unlock Premium Features")
//                                .font(.largeTitle)
//                                .fontWeight(.bold)
//                                .multilineTextAlignment(.center)
//                            
//                            Text("Create unlimited professional invoices and export as PDF")
//                                .font(.title3)
//                                .foregroundColor(.secondary)
//                                .multilineTextAlignment(.center)
//                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                                                
                        // Invoice example image - middle of page
                        VStack(spacing: 16) {
//                            Text("Create Professional Invoices")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                                .multilineTextAlignment(.center)
                            
                            Image("invoiceexample")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                .padding(.horizontal, 20)
                        }
                        // Features - centered
                        HStack {
                            Spacer()
                            VStack(spacing: 20) {
                                PaywallFeature(
                                    icon: "infinity",
                                    title: "Unlimited Invoices"
                                )
                                
                                PaywallFeature(
                                    icon: "square.and.arrow.up.fill",
                                    title: "PDF Export & Share"
                                )
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        
                        // Free trial toggle - compact
                        HStack {
                            Text("Free Trial Enabled")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("", isOn: $isWeeklySelected)
                                .tint(.black)
                                .onChange(of: isWeeklySelected) { _, newValue in
                                    selectedProductID = newValue ? "im_weekly_599" : "im_lifetime"
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        
                        // Pricing plans
                        if !storeManager.products.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(storeManager.products, id: \.id) { product in
                                    PricingCard(
                                        product: product,
                                        isSelected: selectedProductID == product.id,
                                        isTrialEnabled: isWeeklySelected && product.id == "im_weekly_599"
                                    ) {
                                        selectedProductID = product.id
                                        isWeeklySelected = product.id == "im_weekly_599"
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        } else if storeManager.isLoading {
                            ProgressView("Loading plans...")
                                .frame(height: 100)
                        }
                        
                        // Purchase button
                        VStack(spacing: 16) {
                            Button(action: {
                                purchaseSelected()
                            }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(isPurchasing ? "Processing..." : "Continue")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                            }
                            .disabled(isPurchasing || storeManager.products.isEmpty)
                            .padding(.horizontal, 24)
                            
                            // Restore purchases
                            Button("Restore Purchases") {
                                Task {
                                    await storeManager.restorePurchases()
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        // Terms and privacy
                        VStack(spacing: 8) {
                            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            if selectedProductID == "im_weekly_599" {
                                Text("Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isModal {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(storeManager.errorMessage ?? "An error occurred")
        }
        .task {
            await storeManager.loadProducts()
        }
    }
    
    private func purchaseSelected() {
        guard let product = storeManager.products.first(where: { $0.id == selectedProductID }) else { return }
        
        Task {
            isPurchasing = true
            
            do {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    // Purchase successful
                    if isModal {
                        dismiss()
                    }
                }
            } catch {
                storeManager.errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
}

struct PaywallFeature: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.purple)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isTrialEnabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(planTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if product.id == "im_weekly_599" {
                        Text("then $5.99 per week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Text("$249.99")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .strikethrough()
                            Text(product.displayPrice)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Best value badge for lifetime
                if product.id == "im_lifetime" {
                    Text("BEST VALUE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 70)
            .background(isSelected ? Color.blue.opacity(0.05) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var planTitle: String {
        switch product.id {
        case "im_weekly_599":
            return "3-Day Trial"
        case "im_lifetime":
            return "Lifetime Plan"
        default:
            return "Premium Plan"
        }
    }
    
    private var planDescription: String {
        switch product.id {
        case "im_weekly_599":
            return "Perfect for trying out all premium features with weekly flexibility"
        case "im_lifetime":
            return "One-time purchase for lifetime access to all features and future updates"
        default:
            return "Access to all premium features"
        }
    }
}

#Preview {
    PaywallView()
}
