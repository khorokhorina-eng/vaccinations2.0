//
//  ContentView.swift
//  VaccineCalendar
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    
    var body: some View {
        Group {
            if viewModel.isFirstLaunch {
                OnboardingView()
            } else {
                VaccineListView()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(VaccineViewModel())
    }
}