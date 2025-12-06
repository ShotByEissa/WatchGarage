import Foundation

struct Watch: Identifiable {
    let id: Int
    var name: String
    var model: String
    var firstWear: Date
    var batteryLife: Int // in days, usually 730 (2 years)
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: batteryLife, to: firstWear) ?? today
        let days = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return days
    }
    
    var status: BatteryStatus {
        if daysRemaining <= 30 { return .critical }
        if daysRemaining <= 90 { return .warning }
        if daysRemaining <= 180 { return .caution }
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
