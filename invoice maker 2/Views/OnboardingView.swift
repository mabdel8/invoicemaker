//
//  OnboardingView.swift
//  invoice maker 2
//
//  Onboarding view introducing app features
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBlue).opacity(0.1),
                    Color(.systemPurple).opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon and title
                VStack(spacing: 20) {
                    // App icon placeholder - replace with your app icon
//                    Image("invoicemakericon")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 80, height: 80)
//                        .cornerRadius(16)
//                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    
                    VStack(spacing: 8) {
                        Text("Invoice Maker Pro")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
                        
                        Text("Create professional invoices in seconds")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Image("laurel")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 48)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                
                Image("invoiceexample")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 400)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal, 20)
                
                // Features
//                VStack(spacing: 30) {
//                    OnboardingFeature(
//                        icon: "doc.text.fill",
//                        iconColor: .blue,
//                        title: "Professional Templates",
//                        description: "Create beautiful, professional invoices with our polished templates"
//                    )
//                    
//                    OnboardingFeature(
//                        icon: "square.and.arrow.up.fill",
//                        iconColor: .green,
//                        title: "Export & Share",
//                        description: "Generate PDFs and share invoices directly with your clients"
//                    )
//                    
//                    OnboardingFeature(
//                        icon: "chart.bar.fill",
//                        iconColor: .purple,
//                        title: "Track Status",
//                        description: "Keep track of draft, sent, paid, and overdue invoices"
//                    )
//                    
//                    OnboardingFeature(
//                        icon: "icloud.fill",
//                        iconColor: .cyan,
//                        title: "Sync Everywhere",
//                        description: "Your invoices are automatically saved and synced across devices"
//                    )
//                }
//                .padding(.horizontal)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.spring()) {
                        showOnboarding = false
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
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
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingFeature: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                )
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
