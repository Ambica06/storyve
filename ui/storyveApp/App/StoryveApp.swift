//
//  StoryveApp.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 09/05/26.
//
import SwiftUI
import SwiftData

@main
struct StoryveApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: configuration)
        } catch {
            fatalError("Could not create model container")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
