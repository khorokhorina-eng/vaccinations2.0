// Restored original colorful onboarding with questions + interstitials.
// Source: origin/cursor/welcome-screen-and-ui-fixes-c007
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
    
    @State private var step: Step = .intro
    @State private var optionalPreference: OptionalVaccinesPreference = .includeRecommended
    @State private var primaryGoal: PrimaryGoal = .stayOnTrack
    @State private var reminderDays: Int = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            progressDots
                                .padding(.top, 2)
                            
                            stepContent
                                .padding(.top, 6)
                            
                            Color.clear.frame(height: 96)
                        }
                        .padding(.horizontal, 18)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button(action: handlePrimaryAction) {
                        Text(primaryButtonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryButtonEnabled ? Color(red: 0.96, green: 0.29, blue: 0.41) : Color.gray)
                            .cornerRadius(18)
                    }
                    .disabled(!primaryButtonEnabled)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .onAppear {
                // preload persisted preferences (if any)
                optionalPreference = viewModel.dataService.showOnlyMandatoryPreference ? .onlyMandatory : .includeRecommended
                reminderDays = viewModel.dataService.onboardingReminderDays
                if let raw = viewModel.dataService.onboardingPrimaryGoal, let goal = PrimaryGoal(rawValue: raw) {
                    primaryGoal = goal
                }
            }
        }
        // iPad: prevent split-view with empty detail column.
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showCountrySelection) {
            CountrySelectionSheet(selectedCountry: $selectedCountry)
        }
    }
    
    private var primaryButtonTitle: String {
        step == .finalQuestion ? "Get started" : "Next"
    }
    
    private var primaryButtonEnabled: Bool {
        switch step {
        case .nameQuestion:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .countryQuestion:
            return true
        case .birthDateQuestion:
            return true
        case .optionalVaccinesQuestion:
            return true
        case .finalQuestion:
            return true
        default:
            return true
        }
    }
    
    private func handlePrimaryAction() {
        isNameFocused = false
        
        if step == .finalQuestion {
            persistPreferences()
            saveProfile()
            return
        }
        
        withAnimation(.easeInOut) {
            step = step.next
        }
    }
    
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<Step.progressCount, id: \.self) { idx in
                Capsule()
                    .fill(idx == step.progressIndex ? Color(red: 0.96, green: 0.29, blue: 0.41) : Color.gray.opacity(0.25))
                    .frame(width: idx == step.progressIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: step.progressIndex)
            }
        }
        .accessibilityLabel("Onboarding progress")
    }
    
    private var stepContent: some View {
        Group {
            switch step {
            case .intro:
                interstitial(
                    title: "Hi!",
                    subtitle: "Let’s create a personalized vaccination plan for your child.",
                    symbol: "sparkles",
                    accent: Color(red: 0.96, green: 0.29, blue: 0.41)
                )
            case .nameQuestion:
                questionName
            case .betweenNameAndBirth:
                interstitial(
                    title: "Everything under control",
                    subtitle: "Schedules, records, and reminders — in one place.",
                    symbol: "checkmark.seal.fill",
                    accent: Color(red: 0.45, green: 0.32, blue: 0.96)
                )
            case .birthDateQuestion:
                questionBirthDate
            case .betweenBirthAndCountry:
                interstitial(
                    title: "Building your plan",
                    subtitle: "We’ll use your child’s age and your country’s schedule.",
                    symbol: "calendar.badge.clock",
                    accent: Color(red: 0.12, green: 0.55, blue: 0.95)
                )
            case .countryQuestion:
                questionCountry
            case .betweenCountryAndOptional:
                interstitial(
                    title: "Optional vaccines",
                    subtitle: "You can include or hide recommended vaccines — whatever feels right for you.",
                    symbol: "slider.horizontal.3",
                    accent: Color(red: 0.26, green: 0.78, blue: 0.51)
                )
            case .optionalVaccinesQuestion:
                questionOptionalVaccines
            case .betweenOptionalAndFinal:
                interstitial(
                    title: "Make it yours",
                    subtitle: "A couple more details and we’ll personalize everything.",
                    symbol: "wand.and.stars",
                    accent: Color(red: 0.96, green: 0.67, blue: 0.18)
                )
            case .finalQuestion:
                questionPersonalization
            }
        }
    }
    
    private var questionName: some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: "person.crop.circle.fill", accent: Color(red: 0.96, green: 0.29, blue: 0.41))
                .padding(.top, 6)
            
            Text("What’s your child’s name?")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("We’ll use it in reminders and throughout the plan.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Enter a name", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .focused($isNameFocused)
            }
            .padding(.top, 6)
        }
    }
    
    private var questionBirthDate: some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: "calendar", accent: Color(red: 0.12, green: 0.55, blue: 0.95))
                .padding(.top, 6)
            
            Text("When was your child born?")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("We’ll build the vaccination schedule based on age.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Date of birth")
                    .font(.headline)
                
                Button(action: {
                    isNameFocused = false
                    withAnimation(.easeInOut) { showDatePicker.toggle() }
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
                    .cornerRadius(14)
                }
                
                if showDatePicker {
                    VStack(spacing: 10) {
                        DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                        
                        Button("Done") {
                            withAnimation(.easeInOut) { showDatePicker = false }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .transition(.opacity)
                }
            }
            .padding(.top, 6)
        }
    }
    
    private var questionCountry: some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: "globe.europe.africa.fill", accent: Color(red: 0.45, green: 0.32, blue: 0.96))
                .padding(.top, 6)
            
            Text("Which country are you in?")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("We’ll use your country’s recommended vaccination schedule.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Country")
                    .font(.headline)
                
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
                    .cornerRadius(14)
                }
            }
            .padding(.top, 6)
        }
    }
    
    private var questionOptionalVaccines: some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: "shield.lefthalf.filled", accent: Color(red: 0.26, green: 0.78, blue: 0.51))
                .padding(.top, 6)
            
            Text("How do you feel about optional vaccines?")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Choose an option — we’ll set up your list accordingly.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                OnboardingChoiceRow(
                    title: "Show mandatory + recommended",
                    subtitle: "See the complete schedule",
                    isSelected: optionalPreference == .includeRecommended
                ) { optionalPreference = .includeRecommended }
                
                OnboardingChoiceRow(
                    title: "Show mandatory only",
                    subtitle: "Keep things simple",
                    isSelected: optionalPreference == .onlyMandatory
                ) { optionalPreference = .onlyMandatory }
            }
            .padding(.top, 6)
        }
    }
    
    private var questionPersonalization: some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: "slider.horizontal.2.square", accent: Color(red: 0.96, green: 0.67, blue: 0.18))
                .padding(.top, 6)
            
            Text("What matters most to you?")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("This helps us personalize the experience and reminders.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                OnboardingChoiceRow(
                    title: "Never miss a due date",
                    subtitle: "Reminders and upcoming vaccines",
                    isSelected: primaryGoal == .stayOnTrack
                ) { primaryGoal = .stayOnTrack }
                
                OnboardingChoiceRow(
                    title: "Keep vaccination records",
                    subtitle: "History and confirmations in one place",
                    isSelected: primaryGoal == .keepRecords
                ) { primaryGoal = .keepRecords }
                
                OnboardingChoiceRow(
                    title: "Understand what’s mandatory",
                    subtitle: "Clear labels and categories",
                    isSelected: primaryGoal == .understandMandatory
                ) { primaryGoal = .understandMandatory }
            }
            .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("When should we remind you?")
                    .font(.headline)
                    .padding(.top, 10)
                
                HStack(spacing: 10) {
                    ForEach([1, 3, 7], id: \.self) { days in
                        Button(action: { reminderDays = days }) {
                            Text(days == 1 ? "1 day" : "\(days) days")
                                .font(.headline)
                                .foregroundColor(reminderDays == days ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(reminderDays == days ? Color(red: 0.96, green: 0.29, blue: 0.41) : Color(.systemGray6))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func interstitial(title: String, subtitle: String, symbol: String, accent: Color) -> some View {
        VStack(spacing: 16) {
            OnboardingIllustration(symbol: symbol, accent: accent)
                .padding(.top, 6)
            
            Text(title)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Small feature list on the intro screen only
            if step == .intro {
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "calendar.badge.clock", title: "Schedules & reminders", subtitle: "Stay on track effortlessly")
                    FeatureRow(icon: "checkmark.seal", title: "Vaccination records", subtitle: "Keep everything documented")
                    FeatureRow(icon: "tray.full", title: "All in one place", subtitle: "Plan, records, and status")
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
            .opacity(step.canGoBack ? 1 : 0)
            .disabled(!step.canGoBack)
            
            Spacer()
            
            Button(action: skipIfPossible) {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .opacity(step.canSkip ? 1 : 0)
            .disabled(!step.canSkip)
        }
    }
    
    private func goBack() {
        isNameFocused = false
        withAnimation(.easeInOut) {
            step = step.previous ?? step
        }
    }
    
    private func skipIfPossible() {
        guard step.canSkip else { return }
        withAnimation(.easeInOut) {
            step = step.next
        }
    }
    
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.95, blue: 0.97),
                Color(red: 0.97, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func saveProfile() {
        viewModel.saveChildProfile(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            country: selectedCountry.rawValue
        )
    }
    
    private func persistPreferences() {
        // Optional vaccines preference
        let onlyMandatory = optionalPreference == .onlyMandatory
        viewModel.showOnlyMandatory = onlyMandatory
        viewModel.dataService.showOnlyMandatoryPreference = onlyMandatory
        
        // Personalization (future use)
        viewModel.dataService.onboardingPrimaryGoal = primaryGoal.rawValue
        viewModel.dataService.onboardingReminderDays = reminderDays
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

private struct OnboardingIllustration: View {
    let symbol: String
    let accent: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.20),
                            accent.opacity(0.08),
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
            
            Image(systemName: symbol)
                .font(.system(size: 84, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(accent, Color.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct OnboardingChoiceRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41) : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41).opacity(0.12) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41) : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum OptionalVaccinesPreference: String, CaseIterable {
    case includeRecommended
    case onlyMandatory
}

private enum PrimaryGoal: String, CaseIterable {
    case stayOnTrack
    case keepRecords
    case understandMandatory
}

private enum Step: Int, CaseIterable {
    // Interstitials are placed BETWEEN questions (per references)
    case intro
    case nameQuestion
    case betweenNameAndBirth
    case birthDateQuestion
    case betweenBirthAndCountry
    case countryQuestion
    case betweenCountryAndOptional
    case optionalVaccinesQuestion
    case betweenOptionalAndFinal
    case finalQuestion
    
    static var progressCount: Int { 5 } // number of questions
    
    var progressIndex: Int {
        switch self {
        case .nameQuestion: return 0
        case .birthDateQuestion: return 1
        case .countryQuestion: return 2
        case .optionalVaccinesQuestion: return 3
        case .finalQuestion: return 4
        default:
            // Interstitials inherit the previous question index visually
            return max(0, (previous?.progressIndex ?? 0))
        }
    }
    
    var next: Step {
        let all = Step.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return self }
        return all[idx + 1]
    }
    
    var previous: Step? {
        let all = Step.allCases
        guard let idx = all.firstIndex(of: self), idx - 1 >= 0 else { return nil }
        return all[idx - 1]
    }
    
    var canGoBack: Bool {
        return previous != nil
    }
    
    var canSkip: Bool {
        switch self {
        case .intro, .betweenNameAndBirth, .betweenBirthAndCountry, .betweenCountryAndOptional, .betweenOptionalAndFinal:
            return true
        default:
            return false
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
        .navigationViewStyle(StackNavigationViewStyle())
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