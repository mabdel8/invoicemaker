//
//  AppRootView.swift
//  invoice maker 2
//
//  Root view that handles onboarding and paywall flow
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var storeManager: StoreKitManager
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var hasCheckedSubscription = false
    
    var body: some View {
        ZStack {
            // Main app content
            HomeView()
        }
        .onAppear {
            // Check if we should show onboarding
            if appSettings.shouldShowOnboarding() {
                showOnboarding = true
            } else {
                // Wait for subscription status to load, then check if we should show paywall
                checkPaywallAfterDelay()
            }
        }
        .onChange(of: storeManager.hasUnlockedPro) { _, _ in
            // Re-check when subscription status changes
            if hasCheckedSubscription && !showOnboarding {
                checkPaywallAfterDelay()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .onDisappear {
                    // After onboarding, check if we should show paywall
                    checkPaywallAfterDelay()
                }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isModal: true)
        }
    }
    
    private func checkPaywallAfterDelay() {
        // Wait a bit for StoreKit to load subscription status
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            hasCheckedSubscription = true
            
            // Only show paywall if user is NOT subscribed
            if !storeManager.isSubscribed() {
                showPaywall = true
                appSettings.markPaywallSeen()
            }
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppSettings.shared)
        .environmentObject(StoreKitManager.shared)
}