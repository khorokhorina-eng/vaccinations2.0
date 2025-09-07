//
//  VaccineDataLoader.swift
//  VaccineCalendar
//

import Foundation
import Combine
import Network

// MARK: - Vaccine Data Models

struct VaccineData: Codable {
    let mandatory: [Vaccine]
    let recommended: [Vaccine]
}

struct CountryVaccineData: Codable {
    let usa: VaccineData?
    let china: VaccineData?
    let russia: VaccineData?
    let germany: VaccineData?
    let france: VaccineData?
    let italy: VaccineData?
    let brazil: VaccineData?
    let argentina: VaccineData?
    let mexico: VaccineData?
    
    func data(for country: Country) -> VaccineData? {
        switch country {
        case .usa: return usa
        case .china: return china
        case .russia: return russia
        case .germany: return germany
        case .france: return france
        case .italy: return italy
        case .brazil: return brazil
        case .argentina: return argentina
        case .mexico: return mexico
        }
    }
}

// MARK: - Errors

enum VaccineDataLoaderError: LocalizedError {
    case networkError
    case parsingError
    case fileNotFound
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Failed to load vaccine calendar. Please check your internet connection."
        case .parsingError:
            return "Failed to parse vaccine data."
        case .fileNotFound:
            return "Vaccine calendar file not found."
        case .noInternetConnection:
            return "No internet connection. Please connect to the internet to download vaccine calendar."
        }
    }
}

// MARK: - Network Monitor

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private(set) var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Loader

class VaccineDataLoader: ObservableObject {
    static let shared = VaccineDataLoader()
    
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var error: VaccineDataLoaderError?
    
    private let cacheService = CacheService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Main Loader
    
    func loadVaccines(for country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        error = nil
        
        if country.isBuiltIn {
            loadFromBundle(country: country, completion: completion)
        } else {
            if let cachedData = cacheService.getCachedVaccineData(for: country) {
                completion(.success(cachedData))
            } else {
                loadFromNetwork(country: country, completion: completion)
            }
        }
    }
    
    // MARK: - Bundle
    
    private func loadFromBundle(country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        guard let url = Bundle.main.url(forResource: country.localFileName, withExtension: "json") else {
            error = .fileNotFound
            completion(.failure(.fileNotFound))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let vaccineData = try decoder.decode(CountryVaccineData.self, from: data)
            
            if let countryData = vaccineData.data(for: country) {
                completion(.success((countryData.mandatory, countryData.recommended)))
            } else {
                error = .parsingError
                completion(.failure(.parsingError))
            }
        } catch {
            self.error = .parsingError
            completion(.failure(.parsingError))
        }
    }
    
    // MARK: - Network
    
    private func loadFromNetwork(country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        guard let urlString = country.remoteURL,
              let url = URL(string: urlString) else {
            error = .networkError
            completion(.failure(.networkError))
            return
        }
        
        isLoading = true
        loadingProgress = 0.0
        
        if !NetworkMonitor.shared.isConnected {
            isLoading = false
            error = .noInternetConnection
            completion(.failure(.noInternetConnection))
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        let session = URLSession(configuration: configuration)
        
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .prefix(9)
            .sink { [weak self] _ in
                self?.loadingProgress = min(self?.loadingProgress ?? 0 + 0.1, 0.9)
            }
            .store(in: &cancellables)
        
        session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingProgress = 1.0
                
                if error != nil || data == nil {
                    self?.error = .networkError
                    completion(.failure(.networkError))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let vaccineData = try decoder.decode(CountryVaccineData.self, from: data!)
                    
                    if let countryData = vaccineData.data(for: country) {
                        self?.cacheService.cacheVaccineData(
                            mandatory: countryData.mandatory,
                            recommended: countryData.recommended,
                            for: country
                        )
                        completion(.success((countryData.mandatory, countryData.recommended)))
                    } else {
                        self?.error = .parsingError
                        completion(.failure(.parsingError))
                    }
                } catch {
                    self?.error = .parsingError
                    completion(.failure(.parsingError))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.loadingProgress = 0.0
                }
            }
        }.resume()
    }
    
    // MARK: - Sync Methods
    
    func getMandatoryVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        if countryEnum.isBuiltIn {
            if let url = Bundle.main.url(forResource: countryEnum.localFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let vaccineData = try? JSONDecoder().decode(CountryVaccineData.self, from: data),
               let countryData = vaccineData.data(for: countryEnum) {
                return countryData.mandatory
            }
        } else if let cachedData = cacheService.getCachedVaccineData(for: countryEnum) {
            return cachedData.mandatory
        }
        return []
    }
    
    func getRecommendedVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        if countryEnum.isBuiltIn {
            if let url = Bundle.main.url(forResource: countryEnum.localFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let vaccineData = try? JSONDecoder().decode(CountryVaccineData.self, from: data),
               let countryData = vaccineData.data(for: countryEnum) {
                return countryData.recommended
            }
        } else if let cachedData = cacheService.getCachedVaccineData(for: countryEnum) {
            return cachedData.recommended
        }
        return []
    }
    
    func getAllVaccines(for country: String) -> [Vaccine] {
        return getMandatoryVaccines(for: country) + getRecommendedVaccines(for: country)
    }
}
