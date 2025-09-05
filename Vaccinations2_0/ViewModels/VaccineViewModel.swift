//
//  VaccineViewModel.swift
//  VaccineCalendar
//

import Foundation
import SwiftUI
import Combine

// ViewModel для управления данными прививок
class VaccineViewModel: ObservableObject {
    @Published var isFirstLaunch: Bool = true
    @Published var childProfile: ChildProfile?
    @Published var vaccines: [Vaccine] = []
    @Published var vaccineRecords: [VaccineRecord] = []
    @Published var customVaccines: [Vaccine] = []
    @Published var showOnlyMandatory: Bool = false
    @Published var selectedFilter: VaccineFilter = .all
    @Published var isLoadingVaccines: Bool = false
    @Published var loadingError: VaccineDataLoaderError?
    @Published var selectedCountry: Country = .usa
    
    let dataService = DataService.shared
    let vaccineLoader = VaccineDataLoader.shared
    private let cacheService = CacheService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum VaccineFilter: String, CaseIterable {
        case all = "Все"
        case upcoming = "Предстоящие"
        case overdue = "Просроченные"
        case completed = "Сделанные"
        case mandatory = "Обязательные"
        case recommended = "Рекомендованные"
    }
    
    init() {
        loadData()
        setupBindings()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        isFirstLaunch = dataService.isFirstLaunch
        childProfile = dataService.loadChildProfile()
        vaccineRecords = dataService.loadVaccineRecords()
        customVaccines = dataService.loadCustomVaccines()
        
        if let profile = childProfile {
            if let country = Country(rawValue: profile.country) {
                selectedCountry = country
                loadVaccines(for: country)
            } else {
                // Fallback to USA if country is not recognized
                selectedCountry = .usa
                loadVaccines(for: .usa)
            }
        }
    }
    
    private func setupBindings() {
        // Подписываемся на изменения в загрузчике
        vaccineLoader.$isLoading
            .assign(to: &$isLoadingVaccines)
        
        vaccineLoader.$error
            .assign(to: &$loadingError)
    }
    
    func loadVaccines(for country: Country) {
        isLoadingVaccines = true
        loadingError = nil
        
        vaccineLoader.loadVaccines(for: country) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingVaccines = false
                
                switch result {
                case .success(let data):
                    self?.vaccines = data.mandatory + data.recommended + (self?.customVaccines ?? [])
                    // Добавляем страну в список загруженных
                    if !country.isBuiltIn {
                        self?.cacheService.addDownloadedCountry(country)
                    }
                case .failure(let error):
                    self?.loadingError = error
                    // Если не удалось загрузить, пытаемся использовать кеш или пустой список
                    if let cachedData = self?.cacheService.getCachedVaccineData(for: country) {
                        self?.vaccines = cachedData.mandatory + cachedData.recommended + (self?.customVaccines ?? [])
                    } else {
                        self?.vaccines = self?.customVaccines ?? []
                    }
                }
            }
        }
    }
    
    func loadVaccines(for countryString: String) {
        if let country = Country(rawValue: countryString) {
            loadVaccines(for: country)
        }
    }
    
    // MARK: - Profile Management
    
    func saveChildProfile(name: String, birthDate: Date, country: String) {
        let profile = ChildProfile(name: name, birthDate: birthDate, country: country)
        childProfile = profile
        dataService.saveChildProfile(profile)
        dataService.isFirstLaunch = false
        isFirstLaunch = false
        loadVaccines(for: country)
    }
    
    func updateChildProfile(name: String? = nil, birthDate: Date? = nil, country: String? = nil) {
        guard var profile = childProfile else { return }
        
        if let name = name {
            profile.name = name
        }
        if let birthDate = birthDate {
            profile.birthDate = birthDate
        }
        if let country = country {
            profile.country = country
            if let countryEnum = Country(rawValue: country) {
                selectedCountry = countryEnum
                loadVaccines(for: countryEnum)
            }
        }
        
        childProfile = profile
        dataService.saveChildProfile(profile)
    }
    
    // MARK: - Vaccine Records Management
    
    func getRecord(for vaccine: Vaccine) -> VaccineRecord? {
        return vaccineRecords.first(where: { $0.vaccineId == vaccine.id })
    }
    
    func markVaccineDone(vaccine: Vaccine, date: Date = Date(), vaccineName: String? = nil, notes: String? = nil) {
        var record = getRecord(for: vaccine) ?? VaccineRecord(vaccineId: vaccine.id)
        record.markAsDone(date: date, vaccineName: vaccineName, notes: notes)
        saveRecord(record)
    }
    
    func markVaccineNotDone(vaccine: Vaccine) {
        guard var record = getRecord(for: vaccine) else { return }
        record.markAsNotDone()
        saveRecord(record)
    }
    
    func updateVaccineRecord(_ record: VaccineRecord) {
        saveRecord(record)
    }
    
    private func saveRecord(_ record: VaccineRecord) {
        if let index = vaccineRecords.firstIndex(where: { $0.id == record.id }) {
            vaccineRecords[index] = record
        } else {
            vaccineRecords.append(record)
        }
        dataService.saveVaccineRecords(vaccineRecords)
    }
    
    // MARK: - Custom Vaccines
    
    func addCustomVaccine(name: String, disease: String, ageInMonths: Int, ageDescription: String, description: String?) {
        let vaccine = Vaccine(
            id: UUID().uuidString,
            name: name,
            disease: disease,
            ageInMonths: ageInMonths,
            ageDescription: ageDescription,
            isMandatory: false,
            description: description,
            notes: "Добавлено пользователем"
        )
        
        customVaccines.append(vaccine)
        vaccines.append(vaccine)
        dataService.addCustomVaccine(vaccine)
    }
    
    func deleteCustomVaccine(_ vaccine: Vaccine) {
        customVaccines.removeAll(where: { $0.id == vaccine.id })
        vaccines.removeAll(where: { $0.id == vaccine.id })
        dataService.deleteCustomVaccine(withId: vaccine.id)
        
        // Удаляем также запись о прививке, если она есть
        if let record = getRecord(for: vaccine) {
            vaccineRecords.removeAll(where: { $0.id == record.id })
            dataService.deleteVaccineRecord(withId: record.id)
        }
    }
    
    // MARK: - Filtering
    
    var filteredVaccines: [Vaccine] {
        guard let profile = childProfile else { return [] }
        
        var filtered = vaccines
        
        // Фильтр по типу (обязательные/рекомендованные)
        if showOnlyMandatory {
            filtered = filtered.filter { $0.isMandatory }
        }
        
        // Фильтр по статусу
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            filtered = filtered.filter { vaccine in
                let record = getRecord(for: vaccine)
                return record?.isDone != true && vaccine.isUpcoming(birthDate: profile.birthDate)
            }
        case .overdue:
            filtered = filtered.filter { vaccine in
                let record = getRecord(for: vaccine)
                return record?.isDone != true && vaccine.isOverdue(birthDate: profile.birthDate)
            }
        case .completed:
            filtered = filtered.filter { vaccine in
                let record = getRecord(for: vaccine)
                return record?.isDone == true
            }
        case .mandatory:
            filtered = filtered.filter { $0.isMandatory }
        case .recommended:
            filtered = filtered.filter { !$0.isMandatory }
        }
        
        // Сортировка по возрасту
        return filtered.sorted { $0.ageInMonths < $1.ageInMonths }
    }
    
    // MARK: - Statistics
    
    var completedVaccinesCount: Int {
        vaccineRecords.filter { $0.isDone }.count
    }
    
    var totalVaccinesCount: Int {
        vaccines.count
    }
    
    var mandatoryVaccinesCount: Int {
        vaccines.filter { $0.isMandatory }.count
    }
    
    var completedMandatoryCount: Int {
        vaccines.filter { vaccine in
            vaccine.isMandatory && getRecord(for: vaccine)?.isDone == true
        }.count
    }
    
    var overdueVaccinesCount: Int {
        guard let profile = childProfile else { return 0 }
        return vaccines.filter { vaccine in
            let record = getRecord(for: vaccine)
            return record?.isDone != true && vaccine.isOverdue(birthDate: profile.birthDate)
        }.count
    }
    
    var upcomingVaccinesCount: Int {
        guard let profile = childProfile else { return 0 }
        return vaccines.filter { vaccine in
            let record = getRecord(for: vaccine)
            return record?.isDone != true && vaccine.isUpcoming(birthDate: profile.birthDate)
        }.count
    }
    
    // MARK: - Vaccine Status
    
    func getVaccineStatus(_ vaccine: Vaccine) -> VaccineStatus {
        guard let profile = childProfile else { return .scheduled }
        
        if let record = getRecord(for: vaccine), record.isDone {
            return .completed
        }
        
        if vaccine.isOverdue(birthDate: profile.birthDate) {
            return .overdue
        }
        
        if vaccine.isUpcoming(birthDate: profile.birthDate) {
            return .upcoming
        }
        
        return .scheduled
    }
    
    // MARK: - Country Management
    
    func changeCountry(_ country: Country) {
        selectedCountry = country
        updateChildProfile(country: country.rawValue)
    }
    
    func getAvailableCountries() -> [Country] {
        return Country.allCases
    }
    
    func getDownloadedCountries() -> [Country] {
        return cacheService.getDownloadedCountries()
    }
    
    func isCountryAvailable(_ country: Country) -> Bool {
        return country.isBuiltIn || cacheService.isCached(country: country)
    }
    
    func downloadCountryCalendar(_ country: Country, completion: @escaping (Bool) -> Void) {
        loadVaccines(for: country)
        
        // Подписываемся на завершение загрузки
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            completion(self?.loadingError == nil)
        }
    }
    
    func clearCountryCache(_ country: Country) {
        cacheService.clearCache(for: country)
        cacheService.removeDownloadedCountry(country)
        
        // Если это текущая страна, перезагружаем данные
        if country == selectedCountry {
            loadVaccines(for: country)
        }
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        isFirstLaunch = true
        childProfile = nil
        vaccines = []
        vaccineRecords = []
        customVaccines = []
        dataService.resetAllData()
        cacheService.clearAllCache()
    }
}
