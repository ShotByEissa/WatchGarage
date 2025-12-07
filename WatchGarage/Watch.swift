import Foundation

enum MovementType: String, Codable, CaseIterable {
    case quartz = "Quartz"
    case mechanical = "Mechanical"
    case automatic = "Automatic"
    case ecoDrive = "Eco-Drive"
    case solar = "Solar Generic"
    case custom = "Custom"
    
    var serviceInterval: String {
        switch self {
        case .quartz:
            return "2-3 years"
        case .mechanical:
            return "3-5 years"
        case .automatic:
            return "5-10 years"
        case .ecoDrive:
            return "10-15 years (capacitor replacement)"
        case .solar:
            return "10 years (capacitor replacement)"
        case .custom:
            return "Custom interval"
        }
    }
    
    var serviceMonths: Int {
        switch self {
        case .quartz:
            return 30 // 2.5 years
        case .mechanical:
            return 48 // 4 years
        case .automatic:
            return 84 // 7 years
        case .ecoDrive:
            return 120 // 10 years
        case .solar:
            return 120 // 10 years
        case .custom:
            return 60 // 5 years default
        }
    }
    
    var needsBatteryTracking: Bool {
        return self == .quartz || self == .ecoDrive || self == .solar
    }
}

enum BatteryStatus {
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

struct ServiceLog: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var notes: String
}

struct BatteryReplacementLog: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var notes: String
}

struct Watch: Identifiable {
    let id: Int
    var name: String
    var model: String
    var firstWear: Date
    var batteryLife: Int // in days, usually 730 (2 years)
    var movementType: MovementType
    var serviceLogs: [ServiceLog]
    var batteryReplacementLogs: [BatteryReplacementLog]
    
    var lastServiceDate: Date? {
        serviceLogs.sorted(by: { $0.date > $1.date }).first?.date
    }
    
    var lastBatteryReplacementDate: Date? {
        batteryReplacementLogs.sorted(by: { $0.date > $1.date }).first?.date
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let startDate = lastBatteryReplacementDate ?? firstWear
        let endDate = calendar.date(byAdding: .day, value: batteryLife, to: startDate) ?? today
        let days = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return days
    }
    
    var serviceDaysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let serviceDate = lastServiceDate ?? firstWear
        let serviceDays = movementType.serviceMonths * 30
        let endDate = calendar.date(byAdding: .day, value: serviceDays, to: serviceDate) ?? today
        let days = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return days
    }
    
    var status: BatteryStatus {
        if daysRemaining <= 30 { return .critical }
        if daysRemaining <= 90 { return .warning }
        if daysRemaining <= 180 { return .caution }
        return .good
    }
    
    var serviceStatus: BatteryStatus {
        if serviceDaysRemaining <= 90 { return .critical }
        if serviceDaysRemaining <= 180 { return .warning }
        if serviceDaysRemaining <= 365 { return .caution }
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
