//
//  ChildProfile.swift
//  VaccineCalendar
//

import Foundation

// Model representing a child's profile
struct ChildProfile: Codable {
    var name: String
    var birthDate: Date
    var country: String
    
    // Computed properties
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
                return "Newborn"
            } else if months == 1 {
                return "1 month"
            } else if months < 5 {
                return "\(months) months"
            } else {
                return "\(months) months"
            }
        } else if years == 1 {
            if months == 0 {
                return "1 year"
            } else {
                return "1 year \(months) months"
            }
        } else if years < 5 {
            if months == 0 {
                return "\(years) years"
            } else {
                return "\(years) years \(months) months"
            }
        } else {
            if months == 0 {
                return "\(years) years"
            } else {
                return "\(years) years \(months) months"
            }
        }
    }
}

// List of supported countries
enum Country: String, CaseIterable {
    // Built-in calendars (available immediately)
    case usa = "USA"
    case china = "China"
    
    // Downloadable calendars
    case russia = "Russia"
    case germany = "Germany"
    case france = "France"
    case italy = "Italy"
    case brazil = "Brazil"
    case argentina = "Argentina"
    case mexico = "Mexico"
    
    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .china: return "🇨🇳"
        case .russia: return "🇷🇺"
        case .germany: return "🇩🇪"
        case .france: return "🇫🇷"
        case .italy: return "🇮🇹"
        case .brazil: return "🇧🇷"
        case .argentina: return "🇦🇷"
        case .mexico: return "🇲🇽"
        }
    }
    
    var displayName: String {
        switch self {
        case .usa: return "\(flag) United States"
        case .china: return "\(flag) China"
        case .russia: return "\(flag) Russia"
        case .germany: return "\(flag) Germany"
        case .france: return "\(flag) France"
        case .italy: return "\(flag) Italy"
        case .brazil: return "\(flag) Brazil"
        case .argentina: return "\(flag) Argentina"
        case .mexico: return "\(flag) Mexico"
        }
    }
    
    var localizedName: String {
        switch self {
        case .usa: return NSLocalizedString("United States", comment: "")
        case .china: return NSLocalizedString("China", comment: "")
        case .russia: return NSLocalizedString("Russia", comment: "")
        case .germany: return NSLocalizedString("Germany", comment: "")
        case .france: return NSLocalizedString("France", comment: "")
        case .italy: return NSLocalizedString("Italy", comment: "")
        case .brazil: return NSLocalizedString("Brazil", comment: "")
        case .argentina: return NSLocalizedString("Argentina", comment: "")
        case .mexico: return NSLocalizedString("Mexico", comment: "")
        }
    }
    
    // Determines if the calendar is built into the app
    var isBuiltIn: Bool {
        switch self {
        case .usa, .china:
            return true
        default:
            return false
        }
    }
    
    // URL for downloading calendar (for non-built-in countries)
    var remoteURL: String? {
        switch self {
        case .usa, .china:
            return nil // Built-in calendars
        case .russia:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/russia.json"
        case .germany:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/germany.json"
        case .france:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/france.json"
        case .italy:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/italy.json"
        case .brazil:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/brazil.json"
        case .argentina:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/argentina.json"
        case .mexico:
            return "https://raw.githubusercontent.com/vaccine-calendars/data/main/mexico.json"
        }
    }
    
    // File name for the local calendar
    var localFileName: String {
        switch self {
        case .usa: return "vaccines_usa"
        case .china: return "vaccines_china"
        case .russia: return "vaccines_russia"
        default: return "vaccines_\(rawValue.lowercased())"
        }
    }
}
