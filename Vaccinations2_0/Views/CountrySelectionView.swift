//
//  CountrySelectionView.swift
//  VaccineCalendar
//

import SwiftUI

struct CountrySelectionView: View {
    @ObservedObject var viewModel: VaccineViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCountry: Country
    @State private var showDownloadAlert = false
    @State private var isDownloading = false
    @State private var downloadError: String?
    
    init(viewModel: VaccineViewModel) {
        self.viewModel = viewModel
        self._selectedCountry = State(initialValue: viewModel.selectedCountry)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Country")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose a country to view its vaccination schedule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Countries List
                ScrollView {
                    VStack(spacing: 12) {
                        // Built-in countries section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Offline")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(Country.allCases.filter { $0.isBuiltIn }, id: \.self) { country in
                                CountryRow(
                                    country: country,
                                    isSelected: selectedCountry == country,
                                    isAvailable: true,
                                    isBuiltIn: true
                                ) {
                                    selectCountry(country)
                                }
                            }
                        }
                        
                        // Downloadable countries section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Download Required")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(Country.allCases.filter { !$0.isBuiltIn }, id: \.self) { country in
                                CountryRow(
                                    country: country,
                                    isSelected: selectedCountry == country,
                                    isAvailable: viewModel.isCountryAvailable(country),
                                    isBuiltIn: false
                                ) {
                                    selectCountry(country)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    Button(action: confirmSelection) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Select Country")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCountry != viewModel.selectedCountry ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedCountry == viewModel.selectedCountry || isDownloading)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Download Required", isPresented: $showDownloadAlert) {
            Button("Download") {
                downloadCountryData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This country's vaccination calendar needs to be downloaded. This requires an internet connection.")
        }
        .alert("Error", isPresented: .constant(downloadError != nil)) {
            Button("OK") {
                downloadError = nil
            }
        } message: {
            Text(downloadError ?? "An error occurred")
        }
    }
    
    private func selectCountry(_ country: Country) {
        selectedCountry = country
    }
    
    private func confirmSelection() {
        if !selectedCountry.isBuiltIn && !viewModel.isCountryAvailable(selectedCountry) {
            showDownloadAlert = true
        } else {
            viewModel.changeCountry(selectedCountry)
            dismiss()
        }
    }
    
    private func downloadCountryData() {
        isDownloading = true
        
        viewModel.downloadCountryCalendar(selectedCountry) { success in
            isDownloading = false
            
            if success {
                viewModel.changeCountry(selectedCountry)
                dismiss()
            } else {
                downloadError = viewModel.loadingError?.errorDescription ?? "Failed to download vaccination calendar"
            }
        }
    }
}

struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let isAvailable: Bool
    let isBuiltIn: Bool
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
                    
                    if isBuiltIn {
                        Text("Available offline")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if isAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Downloaded")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .font(.caption)
                            Text("Tap to download")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// Loading indicator view
struct LoadingOverlay: View {
    let message: String
    let progress: Double?
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
            
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
    }
}

struct CountrySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelectionView(viewModel: VaccineViewModel())
    }
}