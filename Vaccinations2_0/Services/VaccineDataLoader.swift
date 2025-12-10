//
//  VaccineDataLoader.swift
//  VaccineCalendar
//

import Foundation
import Combine

// MARK: - Vaccine Data Models

struct VaccineData: Codable {
    let mandatory: [Vaccine]
    let recommended: [Vaccine]
}

// MARK: - Errors

enum VaccineDataLoaderError: LocalizedError {
    case parsingError
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .parsingError:
            return "Failed to parse vaccine data."
        case .fileNotFound:
            return "Vaccine calendar file not found."
        }
    }
}

// MARK: - Loader

class VaccineDataLoader: ObservableObject {
    static let shared = VaccineDataLoader()
    
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var error: VaccineDataLoaderError?
    
    private init() {}
    
    // MARK: - Main Loader
    
    func loadVaccines(for country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        error = nil
        isLoading = true
        loadingProgress = 0.2
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.loadFromBundle(country: country)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingProgress = 1.0
                
                switch result {
                case .success:
                    self.error = nil
                case .failure(let error):
                    self.error = error
                }
                
                completion(result)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.loadingProgress = 0.0
                }
            }
        }
    }
    
    // MARK: - Sync Methods
    
    func getMandatoryVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        return (try? loadCountryData(for: countryEnum))?.mandatory ?? []
    }
    
    func getRecommendedVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        return (try? loadCountryData(for: countryEnum))?.recommended ?? []
    }
    
    func getAllVaccines(for country: String) -> [Vaccine] {
        return getMandatoryVaccines(for: country) + getRecommendedVaccines(for: country)
    }
    
    // MARK: - Bundle Helpers
    
    private func loadFromBundle(country: Country) -> Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError> {
        do {
            let countryData = try loadCountryData(for: country)
            return .success((countryData.mandatory, countryData.recommended))
        } catch let error as VaccineDataLoaderError {
            return .failure(error)
        } catch {
            return .failure(.parsingError)
        }
    }
    
    private func loadCountryData(for country: Country) throws -> VaccineData {
        guard let url = Bundle.main.url(forResource: country.localFileName, withExtension: "json") else {
            throw VaccineDataLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let vaccineMap = try decoder.decode([String: VaccineData].self, from: data)
        let key = country.rawValue.lowercased()
        
        guard let countryData = vaccineMap[key] else {
            throw VaccineDataLoaderError.parsingError
        }
        
        return countryData
    }
}
