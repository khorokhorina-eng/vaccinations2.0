//
//  VaccineCalendarApp.swift
//  VaccineCalendar
//

import SwiftUI

@main
struct VaccineCalendarApp: App {
    @StateObject private var viewModel = VaccineViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(subscriptionManager)
        }
    }
}
