//
//  AppSettings.swift
//  invoice maker 2
//
//  UserDefaults wrapper for app settings and preferences
//

import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var hasSeenPaywall: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenPaywall, forKey: "hasSeenPaywall")
        }
    }
    
    @Published var paywallPresentationCount: Int {
        didSet {
            UserDefaults.standard.set(paywallPresentationCount, forKey: "paywallPresentationCount")
        }
    }
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasSeenPaywall = UserDefaults.standard.bool(forKey: "hasSeenPaywall")
        self.paywallPresentationCount = UserDefaults.standard.integer(forKey: "paywallPresentationCount")
    }
    
    func shouldShowOnboarding() -> Bool {
        return !hasCompletedOnboarding
    }
    
    @MainActor
    func shouldShowPaywall() async -> Bool {
        // Always show paywall for non-subscribers
        return !StoreKitManager.shared.isSubscribed()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func markPaywallSeen() {
        hasSeenPaywall = true
        paywallPresentationCount += 1
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenPaywall = false
        paywallPresentationCount = 0
    }
}