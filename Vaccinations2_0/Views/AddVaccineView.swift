//
//  AddVaccineView.swift
//  VaccineCalendar
//

import SwiftUI

struct AddVaccineView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab = 0
    @State private var customVaccineName = ""
    @State private var customDisease = ""
    @State private var customAgeInMonths = 0
    @State private var customDescription = ""
    @State private var selectedRecommendedVaccines: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Рекомендованные").tag(0)
                    Text("Добавить свою").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    recommendedVaccinesView
                } else {
                    customVaccineForm
                }
            }
            .navigationTitle("Добавить прививку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addVaccines()
                    }
                    .disabled(!canAdd)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Успешно"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Recommended Vaccines View
    
    private var recommendedVaccinesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Выберите прививки из рекомендованных")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(availableRecommendedVaccines) { vaccine in
                    RecommendedVaccineRow(
                        vaccine: vaccine,
                        isSelected: selectedRecommendedVaccines.contains(vaccine.id)
                    ) {
                        toggleSelection(vaccine.id)
                    }
                    .padding(.horizontal)
                }
                
                if availableRecommendedVaccines.isEmpty {
                    Text("Все рекомендованные прививки уже добавлены")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Custom Vaccine Form
    
    private var customVaccineForm: some View {
        Form {
            Section(header: Text("Информация о прививке")) {
                TextField("Название прививки", text: $customVaccineName)
                TextField("Заболевание", text: $customDisease)
                
                Stepper(value: $customAgeInMonths, in: 0...1200) {
                    HStack {
                        Text("Возраст:")
                        Spacer()
                        Text(ageDescription)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField("Описание (опционально)", text: $customDescription)
            }
            
            Section {
                Text("Эта прививка будет добавлена как необязательная (рекомендованная)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var availableRecommendedVaccines: [Vaccine] {
        guard let country = viewModel.childProfile?.country else { return [] }
        let recommendedVaccines = VaccineDataLoader.shared.getRecommendedVaccines(for: country)
        
        // Фильтруем уже добавленные прививки
        let addedVaccineIds = Set(viewModel.vaccines.map { $0.id })
        return recommendedVaccines.filter { !addedVaccineIds.contains($0.id) }
    }
    
    private var canAdd: Bool {
        if selectedTab == 0 {
            return !selectedRecommendedVaccines.isEmpty
        } else {
            return !customVaccineName.isEmpty && !customDisease.isEmpty
        }
    }
    
    private var ageDescription: String {
        if customAgeInMonths == 0 {
            return "Новорожденный"
        } else if customAgeInMonths < 12 {
            return "\(customAgeInMonths) мес."
        } else {
            let years = customAgeInMonths / 12
            let months = customAgeInMonths % 12
            if months == 0 {
                return "\(years) " + (years == 1 ? "год" : years < 5 ? "года" : "лет")
            } else {
                return "\(years) " + (years == 1 ? "год" : years < 5 ? "года" : "лет") + " \(months) мес."
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ vaccineId: String) {
        if selectedRecommendedVaccines.contains(vaccineId) {
            selectedRecommendedVaccines.remove(vaccineId)
        } else {
            selectedRecommendedVaccines.insert(vaccineId)
        }
    }
    
    private func addVaccines() {
        if selectedTab == 0 {
            // Добавляем выбранные рекомендованные прививки
            let selectedVaccines = availableRecommendedVaccines.filter {
                selectedRecommendedVaccines.contains($0.id)
            }
            
            for vaccine in selectedVaccines {
                // Добавляем прививку в список
                viewModel.vaccines.append(vaccine)
                
                // Создаем запись для прививки
                let record = VaccineRecord(vaccineId: vaccine.id)
                viewModel.vaccineRecords.append(record)
            }
            
            // Сохраняем изменения
            viewModel.dataService.saveVaccineRecords(viewModel.vaccineRecords)
            
            alertMessage = "Добавлено прививок: \(selectedVaccines.count)"
            showingAlert = true
        } else {
            // Добавляем пользовательскую прививку
            viewModel.addCustomVaccine(
                name: customVaccineName,
                disease: customDisease,
                ageInMonths: customAgeInMonths,
                ageDescription: ageDescription,
                description: customDescription.isEmpty ? nil : customDescription
            )
            
            alertMessage = "Прививка \"\(customVaccineName)\" добавлена"
            showingAlert = true
        }
    }
}

struct RecommendedVaccineRow: View {
    let vaccine: Vaccine
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
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
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddVaccineView_Previews: PreviewProvider {
    static var previews: some View {
        AddVaccineView()
            .environmentObject(VaccineViewModel())
    }
}
