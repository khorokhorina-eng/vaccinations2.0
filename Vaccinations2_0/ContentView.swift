//
//  ContentView.swift
//  VaccineCalendar
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        Group {
            if viewModel.isFirstLaunch {
                OnboardingView()
            } else if viewModel.childProfile != nil && !subscriptionManager.hasPremiumAccess {
                PaywallView()
            } else {
                VaccineListView()
            }
        }
        .onAppear {
            viewModel.loadData()
            Task { await subscriptionManager.refreshEntitlements() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(VaccineViewModel())
    }
}
