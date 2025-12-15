import Foundation

struct Watch: Identifiable, Codable {
    let id: Int
    var name: String
    var model: String
    var firstWear: Date
    var batteryLife: Int // in days, usually 730 (2 years)
    var movementType: MovementType
    var batteryLog: [Date] = []
    var serviceLog: [Date] = []
    var customServiceInterval: Int? // in days, overrides default if set
    
    // Service interval in days based on movement type
    var serviceInterval: Int {
        if let customInterval = customServiceInterval {
            return customInterval
        }
        
        switch movementType {
        case .quartz:
            return 912 // 2.5 years
        case .mechanical:
            return 1460 // 4 years
        case .automatic:
            return 2555 // 7 years
        case .solar:
            return 3650 // 10 years
        case .ecoDrive:
            return 4380 // 12 years
        }
    }
    
    var lastBatteryDate: Date {
        batteryLog.last ?? firstWear
    }
    
    var lastServiceDate: Date {
        serviceLog.last ?? firstWear
    }
    
    var daysUntilBattery: Int {
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: batteryLife, to: lastBatteryDate) ?? today
        let days = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return days
    }
    
    var daysUntilService: Int {
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: serviceInterval, to: lastServiceDate) ?? today
        let days = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return days
    }
    
    var batteryStatus: BatteryStatus {
        if daysUntilBattery <= 30 { return .critical }
        if daysUntilBattery <= 90 { return .warning }
        if daysUntilBattery <= 180 { return .caution }
        return .good
    }
    
    var serviceStatus: BatteryStatus {
        if daysUntilService <= 30 { return .critical }
        if daysUntilService <= 90 { return .warning }
        if daysUntilService <= 180 { return .caution }
        return .good
    }
}

extension Watch: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Watch, rhs: Watch) -> Bool {
        lhs.id == rhs.id
    }
}

enum BatteryStatus: Codable {
    case critical, warning, caution, good
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .warning: return "orange"
        case .caution: return "yellow"
        case .good: return "green"
        }
    }
    
    var label: String {
        switch self {
        case .critical: return "Replace Soon"
        case .warning: return "Plan Replacement"
        case .caution: return "Attention Needed"
        case .good: return "Good Condition"
        }
    }
}

enum MovementType: String, CaseIterable, Codable {
    case quartz = "Quartz"
    case mechanical = "Mechanical"
    case automatic = "Automatic"
    case solar = "Solar"
    case ecoDrive = "Eco-Drive"
    
    var servicingMessage: String {
        switch self {
        case .quartz:
            return "Average servicing time between 2 and 3 years"
        case .mechanical:
            return "Average servicing time between 3 and 5 years"
        case .automatic:
            return "Average servicing time between 5 and 10 years"
        case .solar:
            return "Average servicing time around 10 years"
        case .ecoDrive:
            return "Average servicing time between 10 and 15 years"
        }
    }
}
