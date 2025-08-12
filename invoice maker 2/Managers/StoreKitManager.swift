//
//  StoreKitManager.swift
//  invoice maker 2
//
//  Handles StoreKit purchases and subscription management
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Product IDs
    private let weeklyProductId = "im_weekly_599"
    private let lifetimeProductId = "im_lifetime"
    
    // Published properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var hasUnlockedPro = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Subscription status
    @Published var hasActiveSubscription = false
    @Published var hasLifetimeAccess = false
    @Published var isInTrialPeriod = false
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        
        do {
            let products = try await Product.products(for: [weeklyProductId, lifetimeProductId])
            
            await MainActor.run {
                self.products = products.sorted { first, second in
                    // Sort lifetime first, then weekly
                    if first.id == lifetimeProductId {
                        return true
                    }
                    return false
                }
                self.isLoading = false
            }
        } catch {
            print("Failed to load products: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load products"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            await updateCustomerProductStatus()
            await transaction.finish()
            
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Customer Product Status
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        var hasActive = false
        var hasLifetime = false
        var inTrial = false
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == lifetimeProductId {
                    hasLifetime = true
                    purchasedProducts.insert(transaction.productID)
                } else if transaction.productID == weeklyProductId {
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        hasActive = true
                        purchasedProducts.insert(transaction.productID)
                        
                        // Check if in trial period
                        let originalPurchaseDate = transaction.originalPurchaseDate
                        if let trialPeriod = products.first(where: { $0.id == weeklyProductId })?.subscription?.introductoryOffer?.period {
                            // Simple trial check - if within first week of original purchase
                            let trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: originalPurchaseDate) ?? originalPurchaseDate
                            inTrial = Date() < trialEndDate
                        }
                    }
                }
            } catch {
                print("Failed to check transaction entitlement: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
        self.hasActiveSubscription = hasActive
        self.hasLifetimeAccess = hasLifetime
        self.isInTrialPeriod = inTrial
        self.hasUnlockedPro = hasActive || hasLifetime
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases"
            }
        }
    }
    
    // MARK: - Subscription Info
    
    func isSubscribed() -> Bool {
        return hasUnlockedPro
    }
    
    func weeklyProduct() -> Product? {
        return products.first { $0.id == weeklyProductId }
    }
    
    func lifetimeProduct() -> Product? {
        return products.first { $0.id == lifetimeProductId }
    }
}

enum StoreError: Error {
    case failedVerification
}