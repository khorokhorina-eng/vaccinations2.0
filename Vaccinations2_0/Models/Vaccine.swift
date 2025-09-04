//
//  Vaccine.swift
//  VaccineCalendar
//

import Foundation

// Модель прививки
struct Vaccine: Codable, Identifiable {
    let id: String
    let name: String
    let disease: String
    let ageInMonths: Int // Возраст в месяцах, когда нужно делать прививку
    let ageDescription: String // Человекочитаемое описание возраста
    let isMandatory: Bool // Обязательная или рекомендованная
    let description: String?
    let notes: String?
    
    // Вычисляемое свойство для определения даты прививки на основе даты рождения
    func scheduledDate(birthDate: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: ageInMonths, to: birthDate) ?? Date()
    }
    
    // Проверка, просрочена ли прививка
    func isOverdue(birthDate: Date, currentDate: Date = Date()) -> Bool {
        scheduledDate(birthDate: birthDate) < currentDate
    }
    
    // Проверка, скоро ли прививка (в течение месяца)
    func isUpcoming(birthDate: Date, currentDate: Date = Date()) -> Bool {
        let scheduled = scheduledDate(birthDate: birthDate)
        let monthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        return scheduled >= currentDate && scheduled <= monthFromNow
    }
}

// Расширение для группировки по возрасту
extension Array where Element == Vaccine {
    func groupedByAge() -> [(age: String, vaccines: [Vaccine])] {
        let grouped = Dictionary(grouping: self) { $0.ageDescription }
        return grouped.sorted { first, second in
            let firstAge = first.value.first?.ageInMonths ?? 0
            let secondAge = second.value.first?.ageInMonths ?? 0
            return firstAge < secondAge
        }.map { (age: $0.key, vaccines: $0.value) }
    }
}
