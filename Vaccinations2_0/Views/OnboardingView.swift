//
//  OnboardingView.swift
//  VaccineCalendar
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    
    @State private var step: Int = 0
    private let lastStepIndex: Int = 4
    
    // Onboarding answers (currently used for UX only)
    @State private var wantsReminders: Bool = true
    @State private var wantsMultipleChildren: Bool = true
    
    @State private var childName = ""
    @State private var birthDate = Date()
    @State private var selectedCountry: Country = .usa
    @State private var showCountrySelection = false
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundForStep(step)
                    .ignoresSafeArea()
                
                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    remindersStep.tag(1)
                    privacyStep.tag(2)
                    countryStep.tag(3)
                    profileStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if step < lastStepIndex {
                        Button("Skip") { step = lastStepIndex }
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { bottomControls }
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
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        OnboardingPage(
            title: "CareVax",
            subtitle: "Your child’s vaccination calendar—simple, visual, and always with you.",
            systemImage: "heart.text.square.fill",
            accent: .blue,
            bullets: [
                "Country-specific schedules",
                "Track upcoming and overdue vaccines",
                "Keep records in one place"
            ]
        )
    }
    
    private var remindersStep: some View {
        OnboardingQuestionPage(
            title: "Reminders",
            subtitle: "Would you like to get reminders for upcoming vaccines?",
            systemImage: "bell.badge.fill",
            accent: .orange
        ) {
            Toggle(isOn: $wantsReminders) {
                Text(wantsReminders ? "Yes, remind me" : "No reminders")
                    .font(.headline)
            }
            .toggleStyle(.switch)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var privacyStep: some View {
        OnboardingPage(
            title: "Private by design",
            subtitle: "Your data stays on your device.",
            systemImage: "hand.raised.fill",
            accent: .green,
            bullets: [
                "No account required",
                "No server-side personal data storage",
                "You can delete everything anytime"
            ]
        )
    }
    
    private var countryStep: some View {
        OnboardingQuestionPage(
            title: "Choose a schedule",
            subtitle: "Select the country for your child’s vaccination calendar.",
            systemImage: "globe.europe.africa.fill",
            accent: .teal
        ) {
            Button {
                showCountrySelection = true
            } label: {
                HStack(spacing: 12) {
                    Text(selectedCountry.flag)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCountry.localizedName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("You can change this later")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var profileStep: some View {
        VStack(spacing: 18) {
            OnboardingHeader(
                title: "Create your first profile",
                subtitle: "Add your child to generate a personalized schedule.",
                systemImage: "person.crop.circle.badge.plus",
                accent: .purple
            )
            .padding(.top, 24)
            
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child’s name")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("Enter name", text: $childName)
                        .textInputAutocapitalization(.words)
                        .focused($isNameFocused)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of birth")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    DatePicker(
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    ) {
                        Text(dateFormatter.string(from: birthDate))
                            .font(.headline)
                    }
                    .datePickerStyle(.compact)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    HStack {
                        Text(selectedCountry.flag)
                        Text(selectedCountry.localizedName)
                            .font(.headline)
                        Spacer()
                        Button("Change") { showCountrySelection = true }
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 40)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Bottom controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0...lastStepIndex, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                        .frame(width: i == step ? 18 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }
            .padding(.top, 6)
            
            HStack(spacing: 12) {
                if step > 0 {
                    Button {
                        isNameFocused = false
                        step = max(0, step - 1)
                    } label: {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.20), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                }
                
                Button {
                    isNameFocused = false
                    if step < lastStepIndex {
                        step = min(lastStepIndex, step + 1)
                    } else {
                        saveProfile()
                    }
                } label: {
                    HStack {
                        Text(step < lastStepIndex ? "Continue" : "Start")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (step == lastStepIndex && childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ? Color.white.opacity(0.25)
                        : Color.white.opacity(0.90),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(step < lastStepIndex ? .white : .black)
                .disabled(step == lastStepIndex && childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Background
    
    private func backgroundForStep(_ step: Int) -> some View {
        let gradient: LinearGradient
        switch step {
        case 0:
            gradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            gradient = LinearGradient(colors: [Color.orange, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            gradient = LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            gradient = LinearGradient(colors: [Color.teal, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            gradient = LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        return ZStack {
            gradient
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 360, height: 360)
                .offset(x: 140, y: -220)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260, height: 260)
                .offset(x: -180, y: 220)
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

// MARK: - Onboarding UI building blocks

private struct OnboardingHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 92, height: 92)
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let bullets: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            OnboardingHeader(title: title, subtitle: subtitle, systemImage: systemImage, accent: accent)
                .padding(.top, 30)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { text in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white.opacity(0.95))
                        Text(text)
                            .foregroundColor(.white.opacity(0.95))
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 22)
            
            Spacer()
        }
    }
}

private struct OnboardingQuestionPage<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 18) {
            OnboardingHeader(title: title, subtitle: subtitle, systemImage: systemImage, accent: accent)
                .padding(.top, 30)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(.horizontal, 22)
            
            Spacer()
        }
    }
}