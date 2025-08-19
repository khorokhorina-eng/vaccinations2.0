//
//  VaccineRecord.swift
//  VaccineCalendar
//

import Foundation

// Модель записи о сделанной прививке
struct VaccineRecord: Codable, Identifiable {
    let id: String
    let vaccineId: String
    var isDone: Bool
    var dateAdministered: Date?
    var vaccineName: String? // Конкретное название использованной вакцины
    var batchNumber: String? // Серия вакцины
    var notes: String? // Заметки пользователя
    var sideEffects: String? // Побочные эффекты, если были
    var doctorName: String? // Имя врача
    var clinicName: String? // Название клиники
    
    init(vaccineId: String) {
        self.id = UUID().uuidString
        self.vaccineId = vaccineId
        self.isDone = false
    }
    
    // Метод для отметки прививки как сделанной
    mutating func markAsDone(date: Date = Date(), vaccineName: String? = nil, notes: String? = nil) {
        self.isDone = true
        self.dateAdministered = date
        self.vaccineName = vaccineName
        self.notes = notes
    }
    
    // Метод для отмены отметки
    mutating func markAsNotDone() {
        self.isDone = false
        self.dateAdministered = nil
        self.vaccineName = nil
        self.notes = nil
        self.batchNumber = nil
        self.sideEffects = nil
        self.doctorName = nil
        self.clinicName = nil
    }
}

// Статус прививки для отображения
enum VaccineStatus {
    case completed
    case upcoming
    case overdue
    case scheduled
    
    var color: String {
        switch self {
        case .completed: return "green"
        case .upcoming: return "orange"
        case .overdue: return "red"
        case .scheduled: return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .upcoming: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .scheduled: return "calendar"
        }
    }
    
    var description: String {
        switch self {
        case .completed: return "Сделано"
        case .upcoming: return "Скоро"
        case .overdue: return "Просрочено"
        case .scheduled: return "Запланировано"
        }
    }
}