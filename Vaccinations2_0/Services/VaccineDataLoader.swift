//
//  VaccineDataLoader.swift
//  VaccineCalendar
//

import Foundation
import Combine
import SystemConfiguration

// Структура для парсинга JSON
struct VaccineData: Codable {
    let mandatory: [Vaccine]
    let recommended: [Vaccine]
}

// Единый формат для всех стран
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

// Ошибки загрузки
enum VaccineDataLoaderError: LocalizedError {
    case networkError
    case parsingError
    case fileNotFound
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return NSLocalizedString("Failed to load vaccine calendar. Please check your internet connection.", comment: "")
        case .parsingError:
            return NSLocalizedString("Failed to parse vaccine data.", comment: "")
        case .fileNotFound:
            return NSLocalizedString("Vaccine calendar file not found.", comment: "")
        case .noInternetConnection:
            return NSLocalizedString("No internet connection. Please connect to the internet to download vaccine calendar.", comment: "")
        }
    }
}

// Загрузчик данных о прививках из JSON
class VaccineDataLoader: ObservableObject {
    static let shared = VaccineDataLoader()
    
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var error: VaccineDataLoaderError?
    
    private let cacheService = CacheService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Main Loading Method
    
    func loadVaccines(for country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        // Сбрасываем состояние ошибки
        error = nil
        
        if country.isBuiltIn {
            // Загружаем из bundle
            loadFromBundle(country: country, completion: completion)
        } else {
            // Сначала проверяем кеш
            if let cachedData = cacheService.getCachedVaccineData(for: country) {
                completion(.success(cachedData))
            } else {
                // Загружаем из сети
                loadFromNetwork(country: country, completion: completion)
            }
        }
    }
    
    // MARK: - Bundle Loading
    
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
    
    // MARK: - Network Loading
    
    private func loadFromNetwork(country: Country, completion: @escaping (Result<(mandatory: [Vaccine], recommended: [Vaccine]), VaccineDataLoaderError>) -> Void) {
        guard let urlString = country.remoteURL,
              let url = URL(string: urlString) else {
            error = .networkError
            completion(.failure(.networkError))
            return
        }
        
        isLoading = true
        loadingProgress = 0.0
        
        // Проверяем доступность интернета
        if !isNetworkAvailable() {
            isLoading = false
            error = .noInternetConnection
            completion(.failure(.noInternetConnection))
            return
        }
        
        // Создаем URLSession с конфигурацией
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        let session = URLSession(configuration: configuration)
        
        // Симулируем прогресс загрузки
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .prefix(9) // 0.9 seconds
            .sink { [weak self] _ in
                self?.loadingProgress = min(self?.loadingProgress ?? 0 + 0.1, 0.9)
            }
            .store(in: &cancellables)
        
        session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingProgress = 1.0
                
                if let error = error {
                    print("Network error: \(error)")
                    self?.error = .networkError
                    completion(.failure(.networkError))
                    return
                }
                
                guard let data = data else {
                    self?.error = .networkError
                    completion(.failure(.networkError))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let vaccineData = try decoder.decode(CountryVaccineData.self, from: data)
                    
                    if let countryData = vaccineData.data(for: country) {
                        // Сохраняем в кеш
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
                    print("Parsing error: \(error)")
                    self?.error = .parsingError
                    completion(.failure(.parsingError))
                }
                
                // Сбрасываем прогресс через секунду
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.loadingProgress = 0.0
                }
            }
        }.resume()
    }
    
    // MARK: - Network Availability
    
    private func isNetworkAvailable() -> Bool {
        // Простая проверка доступности сети
        // В реальном приложении лучше использовать Reachability или Network framework
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    // MARK: - Helper Methods
    
    func getAllVaccines(for country: Country, completion: @escaping ([Vaccine]) -> Void) {
        loadVaccines(for: country) { result in
            switch result {
            case .success(let data):
                completion(data.mandatory + data.recommended)
            case .failure:
                completion([])
            }
        }
    }
    
    func getMandatoryVaccines(for country: Country, completion: @escaping ([Vaccine]) -> Void) {
        loadVaccines(for: country) { result in
            switch result {
            case .success(let data):
                completion(data.mandatory)
            case .failure:
                completion([])
            }
        }
    }
    
    func getRecommendedVaccines(for country: Country, completion: @escaping ([Vaccine]) -> Void) {
        loadVaccines(for: country) { result in
            switch result {
            case .success(let data):
                completion(data.recommended)
            case .failure:
                completion([])
            }
        }
    }
    
    // Синхронные методы для обратной совместимости (используют кеш)
    func getMandatoryVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        
        if countryEnum.isBuiltIn {
            // Для встроенных стран загружаем синхронно из bundle
            if let url = Bundle.main.url(forResource: countryEnum.localFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let vaccineData = try? JSONDecoder().decode(CountryVaccineData.self, from: data),
               let countryData = vaccineData.data(for: countryEnum) {
                return countryData.mandatory
            }
        } else {
            // Для остальных стран возвращаем из кеша
            if let cachedData = cacheService.getCachedVaccineData(for: countryEnum) {
                return cachedData.mandatory
            }
        }
        
        return []
    }
    
    func getRecommendedVaccines(for country: String) -> [Vaccine] {
        guard let countryEnum = Country(rawValue: country) else { return [] }
        
        if countryEnum.isBuiltIn {
            // Для встроенных стран загружаем синхронно из bundle
            if let url = Bundle.main.url(forResource: countryEnum.localFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let vaccineData = try? JSONDecoder().decode(CountryVaccineData.self, from: data),
               let countryData = vaccineData.data(for: countryEnum) {
                return countryData.recommended
            }
        } else {
            // Для остальных стран возвращаем из кеша
            if let cachedData = cacheService.getCachedVaccineData(for: countryEnum) {
                return cachedData.recommended
            }
        }
        
        return []
    }
    
    func getAllVaccines(for country: String) -> [Vaccine] {
        return getMandatoryVaccines(for: country) + getRecommendedVaccines(for: country)
    }
    
    // Получение прививок для определенного возраста
    func getVaccinesForAge(months: Int, country: String) -> [Vaccine] {
        let allVaccines = getAllVaccines(for: country)
        return allVaccines.filter { $0.ageInMonths == months }
    }
    
    // Получение предстоящих прививок
    func getUpcomingVaccines(birthDate: Date, country: String, withinMonths: Int = 3) -> [Vaccine] {
        let allVaccines = getAllVaccines(for: country)
        let currentDate = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: withinMonths, to: currentDate) ?? currentDate
        
        return allVaccines.filter { vaccine in
            let scheduledDate = vaccine.scheduledDate(birthDate: birthDate)
            return scheduledDate >= currentDate && scheduledDate <= futureDate
        }
    }
    
    // Получение просроченных прививок
    func getOverdueVaccines(birthDate: Date, country: String, records: [VaccineRecord]) -> [Vaccine] {
        let allVaccines = getAllVaccines(for: country)
        let currentDate = Date()
        
        return allVaccines.filter { vaccine in
            // Проверяем, не сделана ли уже эта прививка
            let record = records.first(where: { $0.vaccineId == vaccine.id })
            if record?.isDone == true {
                return false
            }
            
            // Проверяем, просрочена ли прививка
            return vaccine.scheduledDate(birthDate: birthDate) < currentDate
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache(for country: Country) {
        cacheService.clearCache(for: country)
    }
    
    func clearAllCache() {
        cacheService.clearAllCache()
    }
    
    func isCached(country: Country) -> Bool {
        return cacheService.isCached(country: country)
    }
}