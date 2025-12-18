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
    @State private var step: OnboardingStep = .intro1
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.94),
                        Color.blue.opacity(0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 10)

                    currentStepView
                        .animation(.easeInOut, value: step)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomCTA
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

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case intro1
    case intro2
    case intro3
    case profile
    
    var id: Int { rawValue }
    
    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
    
    var isLast: Bool { self == .profile }
}

private extension OnboardingView {
    @ViewBuilder
    var currentStepView: some View {
        switch step {
        case .intro1:
            introPage(
                icon: "calendar.badge.clock",
                title: "Stay on track",
                subtitle: "A personalized vaccination schedule, built around your child’s age."
            )
            .transition(.opacity)
        case .intro2:
            introPage(
                icon: "bell.badge.fill",
                title: "Never miss a shot",
                subtitle: "See what’s upcoming and what’s overdue at a glance."
            )
            .transition(.opacity)
        case .intro3:
            introPage(
                icon: "globe.europe.africa.fill",
                title: "Country schedules",
                subtitle: "Choose your country to view the recommended vaccination calendar."
            )
            .transition(.opacity)
        case .profile:
            profileForm
                .transition(.opacity)
        }
    }

    var topBar: some View {
        HStack(spacing: 12) {
            ProgressView(value: step.progress)
                .tint(.pink)
                .frame(maxWidth: .infinity)
            
            Button(step.isLast ? "" : "Skip") {
                withAnimation(.easeInOut) {
                    step = .profile
                }
            }
            .opacity(step.isLast ? 0 : 1)
            .disabled(step.isLast)
            .foregroundColor(.secondary)
        }
    }
    
    var bottomCTA: some View {
        VStack(spacing: 10) {
            if step.isLast {
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
                    .background(childName.isEmpty ? Color.gray : Color.pink)
                    .cornerRadius(16)
                }
                .disabled(childName.isEmpty)
            } else {
                Button(action: {
                    goNext()
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(28)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .padding(.top, 10)
        .background(.ultraThinMaterial)
    }
    
    func introPage(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 10)
            
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.10))
                    .frame(width: 180, height: 180)
                Image(systemName: icon)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundColor(.pink)
            }
            .padding(.top, 24)
            
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 40, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    var profileForm: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Vaccination Calendar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create your child’s profile")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 26)
                
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
                            .cornerRadius(10)
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
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Spacer to prevent bottom inset button overlap while scrolling
                Color.clear
                    .frame(height: 100)
            }
        }
    }
    
    private func goNext() {
        isNameFocused = false
        withAnimation(.easeInOut) {
            switch step {
            case .intro1:
                step = .intro2
            case .intro2:
                step = .intro3
            case .intro3:
                step = .profile
            case .profile:
                break
            }
        }
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
        NavigationView {
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