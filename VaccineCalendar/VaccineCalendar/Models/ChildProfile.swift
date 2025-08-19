//
//  ChildProfile.swift
//  VaccineCalendar
//

import Foundation

// Модель профиля ребёнка
struct ChildProfile: Codable {
    var name: String
    var birthDate: Date
    var country: String
    
    // Вычисляемые свойства
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    var ageInMonths: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.month], from: birthDate, to: Date())
        return ageComponents.month ?? 0
    }
    
    var ageDescription: String {
        let years = age
        let months = ageInMonths % 12
        
        if years == 0 {
            if months == 0 {
                return "Новорожденный"
            } else if months == 1 {
                return "1 месяц"
            } else if months < 5 {
                return "\(months) месяца"
            } else {
                return "\(months) месяцев"
            }
        } else if years == 1 {
            if months == 0 {
                return "1 год"
            } else {
                return "1 год \(months) мес."
            }
        } else if years < 5 {
            if months == 0 {
                return "\(years) года"
            } else {
                return "\(years) года \(months) мес."
            }
        } else {
            if months == 0 {
                return "\(years) лет"
            } else {
                return "\(years) лет \(months) мес."
            }
        }
    }
}

// Список поддерживаемых стран
enum Country: String, CaseIterable {
    case russia = "Россия"
    case belarus = "Беларусь"
    case kazakhstan = "Казахстан"
    case ukraine = "Украина"
    
    var flag: String {
        switch self {
        case .russia: return "🇷🇺"
        case .belarus: return "🇧🇾"
        case .kazakhstan: return "🇰🇿"
        case .ukraine: return "🇺🇦"
        }
    }
    
    var displayName: String {
        "\(flag) \(rawValue)"
    }
}