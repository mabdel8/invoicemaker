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
    
    var body: some View {
        ZStack {
            // Main app content
            if storeManager.isSubscribed() {
                // User has premium access - show full app
                HomeView()
            } else {
                // Free user - show limited app with paywall prompts
                HomeView()
                    .onAppear {
                        // Show paywall every time for non-subscribers
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !showOnboarding {
                                showPaywall = true
                                appSettings.markPaywallSeen()
                            }
                        }
                    }
            }
        }
        .onAppear {
            // Check if we should show onboarding
            if appSettings.shouldShowOnboarding() {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .onDisappear {
                    // After onboarding, show paywall for non-subscribers
                    if !storeManager.isSubscribed() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showPaywall = true
                            appSettings.markPaywallSeen()
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isModal: true)
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppSettings.shared)
        .environmentObject(StoreKitManager.shared)
}