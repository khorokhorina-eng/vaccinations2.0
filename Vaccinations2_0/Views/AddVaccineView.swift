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
                    Text("Recommended").tag(0)
                    Text("Add Custom").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    recommendedVaccinesView
                } else {
                    customVaccineForm
                }
            }
            .navigationTitle("Add Vaccine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addVaccines()
                    }
                    .disabled(!canAdd)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Success"),
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
                Text("Select vaccines from recommended list")
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
                    Text("All recommended vaccines are already added")
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
            Section(header: Text("Vaccine Information")) {
                TextField("Vaccine Name", text: $customVaccineName)
                TextField("Disease", text: $customDisease)
                
                Stepper(value: $customAgeInMonths, in: 0...1200) {
                    HStack {
                        Text("Age:")
                        Spacer()
                        Text(ageDescription)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField("Description (optional)", text: $customDescription)
            }
            
            Section {
                Text("This vaccine will be added as optional (recommended)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var availableRecommendedVaccines: [Vaccine] {
        guard let country = viewModel.childProfile?.country else { return [] }
        let recommendedVaccines = VaccineDataLoader.shared.getRecommendedVaccines(for: country)
        
        // Filter out vaccines already added
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
            return "Newborn"
        } else if customAgeInMonths < 12 {
            return "\(customAgeInMonths) months"
        } else {
            let years = customAgeInMonths / 12
            let months = customAgeInMonths % 12
            if months == 0 {
                return "\(years) " + (years == 1 ? "year" : years < 5 ? "years" : "years")
            } else {
                return "\(years) " + (years == 1 ? "year" : years < 5 ? "years" : "years") + " \(months) months"
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
            // Add selected recommended vaccines
            let selectedVaccines = availableRecommendedVaccines.filter {
                selectedRecommendedVaccines.contains($0.id)
            }
            
            for vaccine in selectedVaccines {
                // Add vaccine to the list
                viewModel.vaccines.append(vaccine)
                
                // Create a record for the vaccine
                let record = VaccineRecord(vaccineId: vaccine.id)
                viewModel.vaccineRecords.append(record)
            }
            
            // Save changes
            viewModel.dataService.saveVaccineRecords(viewModel.vaccineRecords)
            
            alertMessage = "Added vaccines: \(selectedVaccines.count)"
            showingAlert = true
        } else {
            // Add custom vaccine
            viewModel.addCustomVaccine(
                name: customVaccineName,
                disease: customDisease,
                ageInMonths: customAgeInMonths,
                ageDescription: ageDescription,
                description: customDescription.isEmpty ? nil : customDescription
            )
            
            alertMessage = "Vaccine \"\(customVaccineName)\" added"
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
