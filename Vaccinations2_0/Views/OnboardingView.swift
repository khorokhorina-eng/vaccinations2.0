//
//  OnboardingView.swift
//  VaccineCalendar
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var selectedCountry = "Россия"
    @State private var showDatePicker = false
    
    let countries = ["Россия", "Беларусь", "Казахстан", "Украина"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Заголовок
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Календарь прививок")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Добро пожаловать!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Форма ввода данных
                VStack(spacing: 20) {
                    // Имя ребёнка
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Имя ребёнка", systemImage: "person.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Введите имя", text: $childName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    // Дата рождения
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Дата рождения", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            HStack {
                                Text(dateFormatter.string(from: birthDate))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
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
                    
                    // Страна проживания
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Страна", systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Страна", selection: $selectedCountry) {
                            ForEach(countries, id: \.self) { country in
                                HStack {
                                    Text(countryFlag(country))
                                    Text(country)
                                }
                                .tag(country)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Кнопка продолжить
                Button(action: {
                    saveProfile()
                }) {
                    HStack {
                        Text("Начать")
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
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .animation(.easeInOut, value: showDatePicker)
        }
    }
    
    private func saveProfile() {
        viewModel.saveChildProfile(
            name: childName,
            birthDate: birthDate,
            country: selectedCountry
        )
    }
    
    private func countryFlag(_ country: String) -> String {
        switch country {
        case "Россия": return "🇷🇺"
        case "Беларусь": return "🇧🇾"
        case "Казахстан": return "🇰🇿"
        case "Украина": return "🇺🇦"
        default: return "🏳️"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(VaccineViewModel())
    }
}
