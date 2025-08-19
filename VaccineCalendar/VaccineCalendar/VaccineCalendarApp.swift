//
//  VaccineCalendarApp.swift
//  VaccineCalendar
//

import SwiftUI

@main
struct VaccineCalendarApp: App {
    @StateObject private var viewModel = VaccineViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}