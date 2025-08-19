//
//  DataService.swift
//  VaccineCalendar
//

import Foundation

// Сервис для работы с данными (UserDefaults)
class DataService {
    static let shared = DataService()
    private let userDefaults = UserDefaults.standard
    
    // Ключи для UserDefaults
    private enum Keys {
        static let isFirstLaunch = "isFirstLaunch"
        static let childProfile = "childProfile"
        static let vaccineRecords = "vaccineRecords"
        static let customVaccines = "customVaccines"
    }
    
    private init() {}
    
    // MARK: - First Launch
    
    var isFirstLaunch: Bool {
        get {
            !userDefaults.bool(forKey: Keys.isFirstLaunch)
        }
        set {
            userDefaults.set(!newValue, forKey: Keys.isFirstLaunch)
        }
    }
    
    // MARK: - Child Profile
    
    func saveChildProfile(_ profile: ChildProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: Keys.childProfile)
        }
    }
    
    func loadChildProfile() -> ChildProfile? {
        guard let data = userDefaults.data(forKey: Keys.childProfile),
              let profile = try? JSONDecoder().decode(ChildProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    func deleteChildProfile() {
        userDefaults.removeObject(forKey: Keys.childProfile)
    }
    
    // MARK: - Vaccine Records
    
    func saveVaccineRecords(_ records: [VaccineRecord]) {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: Keys.vaccineRecords)
        }
    }
    
    func loadVaccineRecords() -> [VaccineRecord] {
        guard let data = userDefaults.data(forKey: Keys.vaccineRecords),
              let records = try? JSONDecoder().decode([VaccineRecord].self, from: data) else {
            return []
        }
        return records
    }
    
    func saveVaccineRecord(_ record: VaccineRecord) {
        var records = loadVaccineRecords()
        
        // Обновляем существующую запись или добавляем новую
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        
        saveVaccineRecords(records)
    }
    
    func getVaccineRecord(for vaccineId: String) -> VaccineRecord? {
        let records = loadVaccineRecords()
        return records.first(where: { $0.vaccineId == vaccineId })
    }
    
    func deleteVaccineRecord(withId id: String) {
        var records = loadVaccineRecords()
        records.removeAll(where: { $0.id == id })
        saveVaccineRecords(records)
    }
    
    // MARK: - Custom Vaccines
    
    func saveCustomVaccines(_ vaccines: [Vaccine]) {
        if let encoded = try? JSONEncoder().encode(vaccines) {
            userDefaults.set(encoded, forKey: Keys.customVaccines)
        }
    }
    
    func loadCustomVaccines() -> [Vaccine] {
        guard let data = userDefaults.data(forKey: Keys.customVaccines),
              let vaccines = try? JSONDecoder().decode([Vaccine].self, from: data) else {
            return []
        }
        return vaccines
    }
    
    func addCustomVaccine(_ vaccine: Vaccine) {
        var vaccines = loadCustomVaccines()
        vaccines.append(vaccine)
        saveCustomVaccines(vaccines)
    }
    
    func deleteCustomVaccine(withId id: String) {
        var vaccines = loadCustomVaccines()
        vaccines.removeAll(where: { $0.id == id })
        saveCustomVaccines(vaccines)
    }
    
    // MARK: - Reset All Data
    
    func resetAllData() {
        userDefaults.removeObject(forKey: Keys.isFirstLaunch)
        userDefaults.removeObject(forKey: Keys.childProfile)
        userDefaults.removeObject(forKey: Keys.vaccineRecords)
        userDefaults.removeObject(forKey: Keys.customVaccines)
    }
}