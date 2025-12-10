//
//  VaccineRecord.swift
//  VaccineCalendar
//

import Foundation

// Model representing a recorded vaccination
struct VaccineRecord: Codable, Identifiable {
    let id: String
    let vaccineId: String
    var isDone: Bool
    var dateAdministered: Date?
    var vaccineName: String? // Specific name of the administered vaccine
    var batchNumber: String? // Vaccine batch number
    var notes: String? // User notes
    var sideEffects: String? // Side effects, if any
    var doctorName: String? // Doctor's name
    var clinicName: String? // Clinic name
    
    init(vaccineId: String) {
        self.id = UUID().uuidString
        self.vaccineId = vaccineId
        self.isDone = false
    }
    
    // Marks the vaccine as administered
    mutating func markAsDone(date: Date = Date(), vaccineName: String? = nil, notes: String? = nil) {
        self.isDone = true
        self.dateAdministered = date
        self.vaccineName = vaccineName
        self.notes = notes
    }
    
    // Cancels the "done" status
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

// Vaccine status for display purposes
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
        case .completed: return "Completed"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        case .scheduled: return "Scheduled"
        }
    }
}
