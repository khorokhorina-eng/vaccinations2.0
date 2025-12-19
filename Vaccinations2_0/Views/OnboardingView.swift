//
//  OnboardingView.swift
//  VaccineCalendar
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @State private var step: Int = 0
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var selectedCountry: Country = .usa
    @State private var showDatePicker = false
    @State private var showCountrySelection = false
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    progressDots
                        .padding(.top, 14)
                    
                    Group {
                        switch step {
                        case 0:
                            welcomeStep
                        case 1:
                            niceToMeetYouStep
                        default:
                            detailsStep
                        }
                    }
                    .padding(.top, 8)
                    
                    // Spacer to prevent bottom inset button overlap while scrolling
                    Color.clear.frame(height: 90)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    handlePrimaryAction()
                }) {
                    HStack {
                        Text(primaryButtonTitle)
                        Image(systemName: step == lastStep ? "checkmark" : "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryButtonEnabled ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!primaryButtonEnabled)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCountrySelection) {
            CountrySelectionSheet(selectedCountry: $selectedCountry)
        }
    }
    
    private var lastStep: Int { 2 }
    
    private var primaryButtonTitle: String {
        switch step {
        case 0:
            return "Далее"
        case 1:
            return "Далее"
        default:
            return "Начать"
        }
    }
    
    private var primaryButtonEnabled: Bool {
        switch step {
        case 0:
            return true
        case 1:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func handlePrimaryAction() {
        isNameFocused = false
        if step < lastStep {
            withAnimation(.easeInOut) {
                step += 1
            }
            return
        }
        saveProfile()
    }
    
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastStep, id: \.self) { idx in
                Capsule()
                    .fill(idx == step ? Color.blue : Color.gray.opacity(0.25))
                    .frame(width: idx == step ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
        .accessibilityLabel("Onboarding progress")
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 84))
                .foregroundColor(.blue)
                .padding(.top, 12)
            
            Text("Привет!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Давай сделаем персонализированный план вакцинаций для твоего ребенка")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "calendar.badge.clock", title: "Сроки и напоминания", subtitle: "Ничего не пропустишь")
                FeatureRow(icon: "checkmark.seal", title: "Отметки о прививках", subtitle: "История всегда под рукой")
                FeatureRow(icon: "tray.full", title: "Всё под контролем", subtitle: "План, записи и статусы в одном месте")
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
        .padding(.horizontal)
    }
    
    private var niceToMeetYouStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text("Nice to meet you")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Ключевой текст про вакцины — крупнее и заметнее
                Text("Сделаем план вакцинаций понятным и наглядным")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Приложение поможет держать всё под контролем: сроки, отметки и напоминания.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 18)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Имя ребенка", systemImage: "person.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Введите имя", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .focused($isNameFocused)
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }
    
    private var detailsStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text("Почти готово")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Ключевой текст про вакцины — крупнее и заметнее
                Text("Осталось выбрать дату рождения и страну — и календарь вакцинаций будет готов")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Приложение поможет держать всё под контролем.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 18)
            
            VStack(spacing: 16) {
                // Birth Date
                VStack(alignment: .leading, spacing: 8) {
                    Label("Дата рождения", systemImage: "calendar")
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
                        VStack(spacing: 10) {
                            // Важно: не сворачиваем календарь на любое изменение даты,
                            // иначе выбрать день невозможно (месяц/год меняются, а до дня не успеваешь).
                            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .labelsHidden()
                            
                            Button("Готово") {
                                withAnimation(.easeInOut) {
                                    showDatePicker = false
                                }
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .transition(.opacity)
                    }
                }
                
                // Country Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Страна", systemImage: "globe")
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
        }
    }
    
    private func saveProfile() {
        viewModel.saveChildProfile(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
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

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.06))
        )
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