//
//  VaccineListView.swift
//  VaccineCalendar
//

import SwiftUI

struct VaccineListView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @State private var showingAddVaccine = false
    @State private var selectedVaccine: Vaccine?
    @State private var searchText = ""
    @State private var showingProfile = false
    @State private var showingCountrySelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Информация о ребёнке
                if let profile = viewModel.childProfile {
                    profileHeader(profile)
                }
                
                // Статистика
                statisticsView
                
                // Фильтры
                filterView
                
                // Список прививок
                if viewModel.filteredVaccines.isEmpty {
                    emptyStateView
                } else {
                    vaccinesList
                }
            }
            .navigationTitle("Календарь прививок")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddVaccine = true
                    }) {
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
                Group {
                    if viewModel.isLoadingVaccines {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        LoadingOverlay(
                            message: "Loading vaccination calendar...",
                            progress: viewModel.vaccineLoader.loadingProgress > 0 ? viewModel.vaccineLoader.loadingProgress : nil
                        )
                    }
                }
            )
            .alert("Error", isPresented: .constant(viewModel.loadingError != nil)) {
                Button("OK") {
                    viewModel.loadingError = nil
                }
                Button("Retry") {
                    viewModel.loadVaccines(for: viewModel.selectedCountry)
                }
            } message: {
                Text(viewModel.loadingError?.errorDescription ?? "An error occurred")
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
                    Button(action: {
                        showingCountrySelection = true
                    }) {
                        HStack(spacing: 4) {
                            if let country = Country(rawValue: profile.country) {
                                Text(country.flag)
                                    .font(.caption)
                                Text(country.localizedName)
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
            
            // Предупреждение о просроченных прививках
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
                    title: "Всего",
                    value: "\(viewModel.completedVaccinesCount)/\(viewModel.totalVaccinesCount)",
                    color: .blue,
                    icon: "chart.pie.fill"
                )
                
                StatCard(
                    title: "Обязательные",
                    value: "\(viewModel.completedMandatoryCount)/\(viewModel.mandatoryVaccinesCount)",
                    color: .green,
                    icon: "checkmark.shield.fill"
                )
                
                StatCard(
                    title: "Просрочено",
                    value: "\(viewModel.overdueVaccinesCount)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatCard(
                    title: "Предстоящие",
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
                        withAnimation {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Vaccines List
    
    private var vaccinesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredVaccines) { vaccine in
                    VaccineRowView(vaccine: vaccine, status: viewModel.getVaccineStatus(vaccine)) {
                        selectedVaccine = vaccine
                    }
                    .environmentObject(viewModel)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Нет прививок")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Попробуйте изменить фильтр или добавить новую прививку")
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
                    Section("Информация о ребёнке") {
                        HStack {
                            Text("Имя")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Дата рождения")
                            Spacer()
                            Text(dateFormatter.string(from: profile.birthDate))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Возраст")
                            Spacer()
                            Text(profile.ageDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Страна")
                            Spacer()
                            Text(profile.country)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            viewModel.resetAllData()
                            showingProfile = false
                        }) {
                            Text("Сбросить все данные")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Профиль")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            showingProfile = false
                        }
                    }
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
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

struct VaccineRowView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    let vaccine: Vaccine
    let status: VaccineStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Иконка статуса
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .frame(width: 40)
                
                // Информация о прививке
                VStack(alignment: .leading, spacing: 4) {
                    Text(vaccine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(vaccine.disease)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(vaccine.ageDescription, systemImage: "calendar")
                            .font(.caption2)
                        
                        if vaccine.isMandatory {
                            Text("Обязательная")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        } else {
                            Text("Рекомендованная")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Кнопка быстрой отметки
                Button(action: {
                    toggleVaccineStatus()
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isCompleted: Bool {
        viewModel.getRecord(for: vaccine)?.isDone ?? false
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .upcoming: return .orange
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
    
    private func toggleVaccineStatus() {
        if isCompleted {
            viewModel.markVaccineNotDone(vaccine: vaccine)
        } else {
            viewModel.markVaccineDone(vaccine: vaccine)
        }
    }
}

struct VaccineListView_Previews: PreviewProvider {
    static var previews: some View {
        VaccineListView()
            .environmentObject(VaccineViewModel())
    }
}
