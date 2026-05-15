//
//  ThreatWatchApp.swift
//  ThreatWatch
//

import SwiftUI

@main
struct ThreatWatchApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
        }
    }
}
