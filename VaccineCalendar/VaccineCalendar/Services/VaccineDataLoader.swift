//
//  VaccineDataLoader.swift
//  VaccineCalendar
//

import Foundation

// Структура для парсинга JSON
struct VaccineData: Codable {
    let mandatory: [Vaccine]
    let recommended: [Vaccine]
}

struct CountryVaccineData: Codable {
    let russia: VaccineData
}

// Загрузчик данных о прививках из JSON
class VaccineDataLoader {
    static let shared = VaccineDataLoader()
    
    private init() {}
    
    // Загрузка данных из JSON файла
    func loadVaccines(for country: String) -> (mandatory: [Vaccine], recommended: [Vaccine])? {
        guard let url = Bundle.main.url(forResource: "vaccines_data", withExtension: "json") else {
            print("Failed to locate vaccines_data.json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let vaccineData = try decoder.decode(CountryVaccineData.self, from: data)
            
            // Пока поддерживаем только Россию
            switch country.lowercased() {
            case "россия", "russia":
                return (vaccineData.russia.mandatory, vaccineData.russia.recommended)
            default:
                // Возвращаем российский календарь по умолчанию
                return (vaccineData.russia.mandatory, vaccineData.russia.recommended)
            }
        } catch {
            print("Failed to decode vaccines_data.json: \(error)")
            return nil
        }
    }
    
    // Получение всех прививок (обязательные + рекомендованные)
    func getAllVaccines(for country: String) -> [Vaccine] {
        guard let data = loadVaccines(for: country) else {
            return []
        }
        return data.mandatory + data.recommended
    }
    
    // Получение только обязательных прививок
    func getMandatoryVaccines(for country: String) -> [Vaccine] {
        guard let data = loadVaccines(for: country) else {
            return []
        }
        return data.mandatory
    }
    
    // Получение только рекомендованных прививок
    func getRecommendedVaccines(for country: String) -> [Vaccine] {
        guard let data = loadVaccines(for: country) else {
            return []
        }
        return data.recommended
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
}