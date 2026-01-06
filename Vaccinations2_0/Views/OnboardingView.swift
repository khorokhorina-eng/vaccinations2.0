//
//  OnboardingView.swift
//  VaccineCalendar
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var selectedCountry: Country = .usa
    @State private var showDatePicker = false
    @State private var showCountrySelection = false
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Vaccination Calendar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Welcome!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Input Form
                    VStack(spacing: 20) {
                        // Child's Name
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Child's Name", systemImage: "person.fill")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter name", text: $childName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .focused($isNameFocused)
                        }
                        
                        // Birth Date
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Date of Birth", systemImage: "calendar")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                isNameFocused = false
                                withAnimation(.easeInOut) {
                                    showDatePicker.toggle()
                                }
                            }) {
                                HStack {
                                    Text(dateFormatter.string(from: birthDate))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            if showDatePicker {
                                DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                        }
                        
                        // Country Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Country", systemImage: "globe")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                isNameFocused = false
                                showCountrySelection = true
                            }) {
                                HStack {
                                    Text(selectedCountry.flag)
                                        .font(.title2)
                                    Text(selectedCountry.localizedName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 560, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Spacer to prevent bottom inset button overlap while scrolling
                    Color.clear
                        .frame(height: 90)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    saveProfile()
                }) {
                    HStack {
                        Text("Start")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(childName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(childName.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .onChange(of: birthDate) { _ in
                // После выбора даты сворачиваем календарь, чтобы было понятно, что делать дальше
                if showDatePicker {
                    withAnimation(.easeInOut) {
                        showDatePicker = false
                    }
                }
            }
        }
        .sheet(isPresented: $showCountrySelection) {
            CountrySelectionSheet(selectedCountry: $selectedCountry)
        }
    }
    
    private func saveProfile() {
        viewModel.saveChildProfile(
            name: childName,
            birthDate: birthDate,
            country: selectedCountry.rawValue
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

// Simplified Country Selection Sheet
struct CountrySelectionSheet: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) var dismiss
    @State private var tempSelection: Country
    
    init(selectedCountry: Binding<Country>) {
        self._selectedCountry = selectedCountry
        self._tempSelection = State(initialValue: selectedCountry.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Countries List
                ScrollView {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Countries")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(Country.allCases, id: \.self) { country in
                                SimpleCountryRow(
                                    country: country,
                                    isSelected: tempSelection == country
                                ) {
                                    tempSelection = country
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: 720, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Bottom button
                Button(action: {
                    selectedCountry = tempSelection
                    dismiss()
                }) {
                    Text("Select")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SimpleCountryRow: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(country.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.localizedName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)
                    
                    Text("Available offline")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(VaccineViewModel())
    }
}