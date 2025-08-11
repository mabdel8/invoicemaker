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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Invoice.self,
            InvoiceItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
