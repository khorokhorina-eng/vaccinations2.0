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
    case usa = "USA"
    case argentina = "Argentina"
    case brazil = "Brazil"
    case china = "China"
    case egypt = "Egypt"
    case france = "France"
    case germany = "Germany"
    case india = "India"
    case italy = "Italy"
    case japan = "Japan"
    case mexico = "Mexico"
    case norway = "Norway"
    case philippines = "Philippines"
    case russia = "Russia"
    case turkey = "Turkey"
    
    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .argentina: return "🇦🇷"
        case .brazil: return "🇧🇷"
        case .china: return "🇨🇳"
        case .egypt: return "🇪🇬"
        case .france: return "🇫🇷"
        case .germany: return "🇩🇪"
        case .india: return "🇮🇳"
        case .italy: return "🇮🇹"
        case .japan: return "🇯🇵"
        case .mexico: return "🇲🇽"
        case .norway: return "🇳🇴"
        case .philippines: return "🇵🇭"
        case .russia: return "🇷🇺"
        case .turkey: return "🇹🇷"
        }
    }
    
    var displayName: String {
        switch self {
        case .usa: return "\(flag) United States"
        case .argentina: return "\(flag) Argentina"
        case .brazil: return "\(flag) Brazil"
        case .china: return "\(flag) China"
        case .egypt: return "\(flag) Egypt"
        case .france: return "\(flag) France"
        case .germany: return "\(flag) Germany"
        case .india: return "\(flag) India"
        case .italy: return "\(flag) Italy"
        case .japan: return "\(flag) Japan"
        case .mexico: return "\(flag) Mexico"
        case .norway: return "\(flag) Norway"
        case .philippines: return "\(flag) Philippines"
        case .russia: return "\(flag) Russia"
        case .turkey: return "\(flag) Turkey"
        }
    }
    
    var localizedName: String {
        switch self {
        case .usa: return NSLocalizedString("United States", comment: "")
        case .argentina: return NSLocalizedString("Argentina", comment: "")
        case .brazil: return NSLocalizedString("Brazil", comment: "")
        case .china: return NSLocalizedString("China", comment: "")
        case .egypt: return NSLocalizedString("Egypt", comment: "")
        case .france: return NSLocalizedString("France", comment: "")
        case .germany: return NSLocalizedString("Germany", comment: "")
        case .india: return NSLocalizedString("India", comment: "")
        case .italy: return NSLocalizedString("Italy", comment: "")
        case .japan: return NSLocalizedString("Japan", comment: "")
        case .mexico: return NSLocalizedString("Mexico", comment: "")
        case .norway: return NSLocalizedString("Norway", comment: "")
        case .philippines: return NSLocalizedString("Philippines", comment: "")
        case .russia: return NSLocalizedString("Russia", comment: "")
        case .turkey: return NSLocalizedString("Turkey", comment: "")
        }
    }
    
    // File name for the local calendar
    var localFileName: String {
        switch self {
        case .usa: return "vaccines_usa"
        case .china: return "vaccines_china"
        default: return "vaccines_data"
        }
    }
}
