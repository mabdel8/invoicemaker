//
//  invoice_maker_2App.swift
//  invoice maker 2
//
//  Created by Mohamed Abdelmagid on 8/10/25.
//

import SwiftUI
import SwiftData

@main
struct invoice_maker_2App: App {
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var sharedModelContainer: ModelContainer? = {
        let schema = Schema([
            Invoice.self,
            InvoiceItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log error for debugging
            print("Failed to create ModelContainer: \(error)")
            
            // Try to create an in-memory container as fallback
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                print("Failed to create fallback ModelContainer: \(error)")
                return nil
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                HomeView()
                    .modelContainer(container)
            } else {
                // Show error view when container fails to initialize
                DataErrorView()
            }
        }
    }
}

// Error view shown when data container fails to initialize
struct DataErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Unable to Load Data")
                .font(.title)
                .fontWeight(.bold)
            
            Text("The app encountered an error while setting up the database. Please try:")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Restart the app", systemImage: "arrow.clockwise")
                Label("Free up device storage", systemImage: "internaldrive")
                Label("Update to the latest iOS version", systemImage: "gear")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Button(action: {
                // Attempt to restart the app
                exit(0)
            }) {
                Text("Quit App")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
