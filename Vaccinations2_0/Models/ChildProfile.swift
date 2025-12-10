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
    case china = "China"
    case russia = "Russia"
    case germany = "Germany"
    case france = "France"
    case italy = "Italy"
    case brazil = "Brazil"
    case argentina = "Argentina"
    case mexico = "Mexico"
    case india = "India"
    case turkey = "Turkey"
    case japan = "Japan"
    case norway = "Norway"
    case egypt = "Egypt"
    case philippines = "Philippines"
    
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
        case .india: return "🇮🇳"
        case .turkey: return "🇹🇷"
        case .japan: return "🇯🇵"
        case .norway: return "🇳🇴"
        case .egypt: return "🇪🇬"
        case .philippines: return "🇵🇭"
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
        case .india: return "\(flag) India"
        case .turkey: return "\(flag) Turkey"
        case .japan: return "\(flag) Japan"
        case .norway: return "\(flag) Norway"
        case .egypt: return "\(flag) Egypt"
        case .philippines: return "\(flag) Philippines"
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
        case .india: return NSLocalizedString("India", comment: "")
        case .turkey: return NSLocalizedString("Turkey", comment: "")
        case .japan: return NSLocalizedString("Japan", comment: "")
        case .norway: return NSLocalizedString("Norway", comment: "")
        case .egypt: return NSLocalizedString("Egypt", comment: "")
        case .philippines: return NSLocalizedString("Philippines", comment: "")
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
