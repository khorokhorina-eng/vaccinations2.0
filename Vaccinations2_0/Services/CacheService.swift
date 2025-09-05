//
//  CacheService.swift
//  VaccineCalendar
//

import Foundation

// Сервис для кеширования данных о календарях прививок
class CacheService {
    static let shared = CacheService()
    private let userDefaults = UserDefaults.standard
    
    // Префикс для ключей кеша
    private let cacheKeyPrefix = "vaccine_cache_"
    private let cacheTimestampPrefix = "vaccine_cache_timestamp_"
    
    // Время жизни кеша в секундах (30 дней)
    private let cacheLifetime: TimeInterval = 30 * 24 * 60 * 60
    
    private init() {}
    
    // MARK: - Cache Management
    
    func cacheVaccineData(mandatory: [Vaccine], recommended: [Vaccine], for country: Country) {
        let data = VaccineData(mandatory: mandatory, recommended: recommended)
        
        if let encoded = try? JSONEncoder().encode(data) {
            let key = cacheKeyPrefix + country.rawValue
            let timestampKey = cacheTimestampPrefix + country.rawValue
            
            userDefaults.set(encoded, forKey: key)
            userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        }
    }
    
    func getCachedVaccineData(for country: Country) -> (mandatory: [Vaccine], recommended: [Vaccine])? {
        let key = cacheKeyPrefix + country.rawValue
        let timestampKey = cacheTimestampPrefix + country.rawValue
        
        // Проверяем наличие данных
        guard let data = userDefaults.data(forKey: key),
              let vaccineData = try? JSONDecoder().decode(VaccineData.self, from: data) else {
            return nil
        }
        
        // Проверяем актуальность кеша
        let timestamp = userDefaults.double(forKey: timestampKey)
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime - timestamp > cacheLifetime {
            // Кеш устарел, удаляем его
            clearCache(for: country)
            return nil
        }
        
        return (vaccineData.mandatory, vaccineData.recommended)
    }
    
    func isCached(country: Country) -> Bool {
        let key = cacheKeyPrefix + country.rawValue
        return userDefaults.data(forKey: key) != nil
    }
    
    func clearCache(for country: Country) {
        let key = cacheKeyPrefix + country.rawValue
        let timestampKey = cacheTimestampPrefix + country.rawValue
        
        userDefaults.removeObject(forKey: key)
        userDefaults.removeObject(forKey: timestampKey)
    }
    
    func clearAllCache() {
        // Удаляем все кешированные данные
        for country in Country.allCases {
            clearCache(for: country)
        }
    }
    
    // MARK: - Cache Information
    
    func getCacheDate(for country: Country) -> Date? {
        let timestampKey = cacheTimestampPrefix + country.rawValue
        let timestamp = userDefaults.double(forKey: timestampKey)
        
        if timestamp > 0 {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
    
    func getCacheSize(for country: Country) -> Int {
        let key = cacheKeyPrefix + country.rawValue
        return userDefaults.data(forKey: key)?.count ?? 0
    }
    
    func getTotalCacheSize() -> Int {
        var totalSize = 0
        for country in Country.allCases {
            totalSize += getCacheSize(for: country)
        }
        return totalSize
    }
    
    // MARK: - Downloaded Countries
    
    private let downloadedCountriesKey = "downloaded_countries"
    
    func getDownloadedCountries() -> [Country] {
        guard let data = userDefaults.data(forKey: downloadedCountriesKey),
              let countries = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return countries.compactMap { Country(rawValue: $0) }
    }
    
    func addDownloadedCountry(_ country: Country) {
        var countries = getDownloadedCountries()
        if !countries.contains(country) {
            countries.append(country)
            saveDownloadedCountries(countries)
        }
    }
    
    func removeDownloadedCountry(_ country: Country) {
        var countries = getDownloadedCountries()
        countries.removeAll { $0 == country }
        saveDownloadedCountries(countries)
        clearCache(for: country)
    }
    
    private func saveDownloadedCountries(_ countries: [Country]) {
        let countryStrings = countries.map { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(countryStrings) {
            userDefaults.set(encoded, forKey: downloadedCountriesKey)
        }
    }
}