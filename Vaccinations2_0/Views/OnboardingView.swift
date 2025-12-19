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

    @State private var optionalVaccinesPreference: OptionalVaccinesPreference? = nil
    @State private var personalizationGoal: PersonalizationGoal? = nil

    @State private var showingBirthDatePickerSheet = false
    @State private var showCountrySelection = false

    @FocusState private var isNameFocused: Bool
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        NavigationView {
            ZStack {
                background

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
        }
        .sheet(isPresented: $showingBirthDatePickerSheet) {
            NavigationView {
                DatePicker(
                    "",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
                .navigationTitle("Select date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingBirthDatePickerSheet = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingBirthDatePickerSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCountrySelection) {
            CountrySelectionSheet(selectedCountry: $selectedCountry)
        }
    }

    // MARK: - UI pieces

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.94),
                Color.pink.opacity(0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { goBack() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(canGoBack ? .primary : .clear)
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(canGoBack ? 0.06 : 0))
                    .clipShape(Circle())
            }
            .disabled(!canGoBack)

            ProgressView(value: step.progress)
                .tint(.pink)
                .frame(maxWidth: .infinity)

            Button(step.isLast ? "" : "Skip") {
                withAnimation(.easeInOut) {
                    step = .phraseBeforeStart
                    isNameFocused = false
                    showingBirthDatePickerSheet = false
                }
            }
            .opacity(step.isLast ? 0 : 1)
            .disabled(step.isLast)
            .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .welcome:
            phrasePage(
                imageSystemName: "heart.text.square.fill",
                title: "Hi!",
                highlight: "Let’s create a personalized vaccination plan for your child.",
                body: "Answer a few quick questions and the app will help you keep everything under control."
            )

        case .name:
            questionContainer(
                imageSystemName: "person.fill",
                imageTint: .pink,
                title: "What is your child’s name?",
                subtitle: "We’ll use it in the schedule and reminders."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Enter name", text: $childName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .focused($isNameFocused)

                    Text("You can change it later in Profile.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

        case .phraseAfterName:
            phrasePage(
                imageSystemName: "sparkles",
                title: "Nice to meet you!",
                highlight: "Vaccines work best when given on time.",
                body: "We’ll help you stay on schedule and keep everything under control."
            )

        case .birthDate:
            questionContainer(
                imageSystemName: "calendar",
                imageTint: .blue,
                title: "When was your child born?",
                subtitle: "This helps us calculate vaccine timing."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: {
                        isNameFocused = false
                        showingBirthDatePickerSheet = true
                    }) {
                        HStack {
                            Text(dateFormatter.string(from: birthDate))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    Text("Tap to choose a date.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

        case .country:
            questionContainer(
                imageSystemName: "globe.europe.africa.fill",
                imageTint: .green,
                title: "Which country schedule should we use?",
                subtitle: "You can switch country anytime later."
            ) {
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
                    .cornerRadius(12)
                }
            }

        case .optionalVaccines:
            questionContainer(
                imageSystemName: "checkmark.shield.fill",
                imageTint: .orange,
                title: "How do you feel about optional vaccines?",
                subtitle: "This only changes what we show by default."
            ) {
                VStack(spacing: 12) {
                    choiceRow(
                        title: "Show all (mandatory + recommended)",
                        subtitle: "Best for full visibility",
                        isSelected: optionalVaccinesPreference == .includeRecommended
                    ) {
                        optionalVaccinesPreference = .includeRecommended
                    }

                    choiceRow(
                        title: "Focus on mandatory only",
                        subtitle: "Keep it simple",
                        isSelected: optionalVaccinesPreference == .mandatoryOnly
                    ) {
                        optionalVaccinesPreference = .mandatoryOnly
                    }

                    choiceRow(
                        title: "I’ll decide later",
                        subtitle: "You can change this anytime",
                        isSelected: optionalVaccinesPreference == .decideLater
                    ) {
                        optionalVaccinesPreference = .decideLater
                    }
                }
            }

        case .personalization:
            questionContainer(
                imageSystemName: "slider.horizontal.3",
                imageTint: .purple,
                title: "What do you want to prioritize?",
                subtitle: "We’ll adapt the experience based on your choice."
            ) {
                VStack(spacing: 12) {
                    choiceRow(
                        title: "Deadlines & reminders",
                        subtitle: "Keep me on schedule",
                        isSelected: personalizationGoal == .reminders
                    ) {
                        personalizationGoal = .reminders
                    }

                    choiceRow(
                        title: "Simplicity",
                        subtitle: "Show the essentials first",
                        isSelected: personalizationGoal == .simplicity
                    ) {
                        personalizationGoal = .simplicity
                    }

                    choiceRow(
                        title: "Learn more",
                        subtitle: "More context in details",
                        isSelected: personalizationGoal == .learnMore
                    ) {
                        personalizationGoal = .learnMore
                    }
                }
            }

        case .phraseBeforeStart:
            phrasePage(
                imageSystemName: "heart.text.square.fill",
                title: "You’re all set!",
                highlight: "On-time vaccines build strong protection early.",
                body: "Your personalized plan is ready—this app will help you stay on track."
            )
        }
    }

    private var bottomCTA: some View {
        VStack(spacing: 10) {
            if step.isLast {
                Button(action: { saveProfile() }) {
                    HStack {
                        Text("Start")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStart ? Color.pink : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!canStart)
            } else {
                Button(action: { goNext() }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nextEnabled ? Color.pink : Color.gray)
                        .cornerRadius(28)
                }
                .disabled(!nextEnabled)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .padding(.top, 10)
        .background(.ultraThinMaterial)
    }

    private var nextEnabled: Bool {
        switch step {
        case .welcome:
            return true
        case .name:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .birthDate, .country:
            return true
        case .optionalVaccines:
            return optionalVaccinesPreference != nil
        case .personalization:
            return personalizationGoal != nil
        case .phraseAfterName:
            return true
        case .phraseBeforeStart:
            return false
        }
    }

    private var canStart: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canGoBack: Bool {
        step != .welcome
    }

    private func questionContainer(
        imageSystemName: String,
        imageTint: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 6)

                onboardingIllustration(symbol: imageSystemName, tint: imageTint)
                    .padding(.top, 14)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 34, weight: .heavy))
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.top, 4)
                .padding(.horizontal, 2)

                Color.clear
                    .frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isNameFocused = false
        }
    }

    private func phrasePage(imageSystemName: String, title: String, highlight: String, body: String) -> some View {
        VStack(spacing: 18) {
            Spacer(minLength: 14)

            onboardingIllustration(symbol: imageSystemName, tint: .pink)
                .padding(.top, 16)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 40, weight: .heavy))
                    .multilineTextAlignment(.center)

                Text(highlight)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                Text(body)
                    .font(.body)
                    .foregroundColor(.primary.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
    }

    private func onboardingIllustration(symbol: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.10))
                .frame(width: 180, height: 180)
            Circle()
                .strokeBorder(tint.opacity(0.15), lineWidth: 2)
                .frame(width: 180, height: 180)
            Image(systemName: symbol)
                .font(.system(size: 66, weight: .semibold))
                .foregroundColor(tint)
        }
    }

    private func choiceRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .pink : .secondary)
                    .font(.title3)

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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.pink : Color.gray.opacity(0.18), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation

    private func goNext() {
        isNameFocused = false
        showingBirthDatePickerSheet = false

        withAnimation(.easeInOut) {
            switch step {
            case .welcome:
                step = .name
            case .name:
                step = .phraseAfterName
            case .phraseAfterName:
                step = .birthDate
            case .birthDate:
                step = .country
            case .country:
                step = .optionalVaccines
            case .optionalVaccines:
                step = .personalization
            case .personalization:
                step = .phraseBeforeStart
            case .phraseBeforeStart:
                break
            }
        }
    }

    private func goBack() {
        guard canGoBack else { return }

        isNameFocused = false
        showingBirthDatePickerSheet = false

        withAnimation(.easeInOut) {
            switch step {
            case .welcome:
                break
            case .name:
                step = .welcome
            case .phraseAfterName:
                step = .name
            case .birthDate:
                step = .phraseAfterName
            case .country:
                step = .birthDate
            case .optionalVaccines:
                step = .country
            case .personalization:
                step = .optionalVaccines
            case .phraseBeforeStart:
                step = .personalization
            }
        }
    }

    // MARK: - Saving

    private func saveProfile() {
        saveOnboardingPreferences()

        viewModel.saveChildProfile(
            name: childName,
            birthDate: birthDate,
            country: selectedCountry.rawValue
        )
    }

    private func saveOnboardingPreferences() {
        // Persist preferences for future app launches
        let ds = viewModel.dataService

        if let optionalVaccinesPreference {
            ds.optionalVaccinesPreference = optionalVaccinesPreference.rawValue
            viewModel.showOnlyMandatory = (optionalVaccinesPreference == .mandatoryOnly)
        } else {
            ds.optionalVaccinesPreference = nil
        }

        if let personalizationGoal {
            ds.personalizationGoal = personalizationGoal.rawValue
        } else {
            ds.personalizationGoal = nil
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case name
    case phraseAfterName
    case birthDate
    case country
    case optionalVaccines
    case personalization
    case phraseBeforeStart

    var id: Int { rawValue }

    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var isLast: Bool {
        self == .phraseBeforeStart
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
