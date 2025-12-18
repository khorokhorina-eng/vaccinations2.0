//
//  VaccineListView.swift
//  VaccineCalendar
//

import SwiftUI

struct VaccineListView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddVaccine = false
    @State private var selectedVaccine: Vaccine?
    @State private var searchText = ""
    @State private var showingProfile = false
    @State private var showingCountrySelection = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Child profile header
                        if let profile = viewModel.childProfile {
                            profileHeader(profile)
                        }
                        
                        // Statistics
                        statisticsView
                        
                        // Filter chips
                        filterView
                        
                        // Vaccine list
                        if viewModel.filteredVaccines.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredVaccines) { vaccine in
                                    VaccineRowView(
                                        vaccine: vaccine,
                                        status: viewModel.getVaccineStatus(vaccine)
                                    ) {
                                        selectedVaccine = vaccine
                                    }
                                    .environmentObject(viewModel)
                                }
                            }
                            .padding(.top)
                            .padding(.horizontal)
                            .padding(.bottom, 120) // space for disclaimer
                        }
                    }
                }
                
                // Fixed disclaimer at the bottom
                CollapsibleDisclaimerView()
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
                    .shadow(radius: 5)
            }
            .navigationTitle("Vaccination Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVaccine = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVaccine) {
                AddVaccineView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedVaccine) { vaccine in
                VaccineDetailView(vaccine: vaccine)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingProfile) {
                profileEditView
            }
            .sheet(isPresented: $showingCountrySelection) {
                CountrySelectionView(viewModel: viewModel)
            }
            .overlay(
                loadingOverlay
            )
            .alert("Error", isPresented: .constant(viewModel.loadingError != nil)) {
                Button("OK") { viewModel.loadingError = nil }
                Button("Retry") { viewModel.loadVaccines(for: viewModel.selectedCountry) }
            } message: {
                Text(viewModel.loadingError?.errorDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoadingVaccines {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    LoadingOverlay(
                        message: "Loading vaccination calendar...",
                        progress: viewModel.vaccineLoader.loadingProgress > 0 ? viewModel.vaccineLoader.loadingProgress : nil
                    )
                }
            }
        }
    }
    
    // MARK: - Profile Header
    
    private func profileHeader(_ profile: ChildProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label(profile.ageDescription, systemImage: "birthday.cake")
                    Text("•")
                    Button(action: { showingCountrySelection = true }) {
                        HStack(spacing: 4) {
                            if let country = Country(rawValue: profile.country) {
                                Text(country.flag)
                                    .font(.caption)
                                Text(country.displayName)
                                    .font(.caption)
                            } else {
                                Label(profile.country, systemImage: "globe")
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.overdueVaccinesCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\(viewModel.overdueVaccinesCount)")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Statistics View
    
    private var statisticsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.completedVaccinesCount)/\(viewModel.totalVaccinesCount)",
                    color: .blue,
                    icon: "chart.pie.fill"
                )
                
                StatCard(
                    title: "Mandatory",
                    value: "\(viewModel.completedMandatoryCount)/\(viewModel.mandatoryVaccinesCount)",
                    color: .green,
                    icon: "checkmark.shield.fill"
                )
                
                StatCard(
                    title: "Overdue",
                    value: "\(viewModel.overdueVaccinesCount)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatCard(
                    title: "Upcoming",
                    value: "\(viewModel.upcomingVaccinesCount)",
                    color: .orange,
                    icon: "clock.fill"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Filter View
    
    private var filterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VaccineViewModel.VaccineFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation { viewModel.selectedFilter = filter }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Vaccines")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try changing the filter or adding a new vaccine")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Profile Edit View
    
    private var profileEditView: some View {
        NavigationView {
            if let profile = viewModel.childProfile {
                Form {
                    Section("Child Information") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Birth Date")
                            Spacer()
                            Text(dateFormatter.string(from: profile.birthDate))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Age")
                            Spacer()
                            Text(profile.ageDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Country")
                            Spacer()
                            Text(profile.country)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            Task { await subscriptionManager.resetPromoUnlockAndRefresh() }
                            viewModel.resetAllData()
                            showingProfile = false
                        }) {
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showingProfile = false }
                    }
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(minWidth: 100)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .cornerRadius(15)
        }
    }
}
// MARK: - Vaccine Row

struct VaccineRowView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    let vaccine: Vaccine
    let status: VaccineStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vaccine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(vaccine.disease)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(vaccine.ageDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .upcoming: return .orange
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
}

// MARK: - Collapsible Disclaimer View

struct CollapsibleDisclaimerView: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Disclaimer")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                }) {
                    Label(isExpanded ? "Hide" : "More", systemImage: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CareVax provides publicly available vaccination schedule data for informational purposes only.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Sources:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Link("Centers for Disease Control and Prevention (CDC)", destination: URL(string: "https://www.cdc.gov/vaccines-children/schedules/index.html")!)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .underline()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Link("World Health Organization (WHO)", destination: URL(string: "https://www.who.int/publications/m/item/table1-summary-of-who-position-papers-recommendations-for-routine-immunization")!)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .underline()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Always consult your healthcare provider for personalized medical advice.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
