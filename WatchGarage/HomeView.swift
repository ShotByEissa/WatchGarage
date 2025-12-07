import SwiftUI

struct HomeView: View {
    @Binding var watches: [Watch]
    @Binding var showingAddWatch: Bool
    
    var nextBatteryWatch: Watch? {
        watches.sorted(by: { $0.daysRemaining < $1.daysRemaining }).first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Watch Count Card with Add Button
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Watches")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(watches.count)")
                                .font(.system(size: 48, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { showingAddWatch = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Next Battery Replacement Card
                    if let watch = nextBatteryWatch {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Battery Replacement")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(watch.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(watch.model)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(formatTimeRemaining(watch.daysRemaining))
                                    .font(.headline)
                                    .foregroundColor(statusColor(watch.status))
                                Spacer()
                                Image(systemName: "battery.25")
                                    .foregroundColor(statusColor(watch.status))
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Next Service Card (Placeholder)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Service")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("No service data yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Watch Garage")
        }
    }
    
    func formatTimeRemaining(_ days: Int) -> String {
        if days < 0 { return "OVERDUE" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        
        if days < 365 {
            let months = days / 30
            let remainingDays = days % 30
            if remainingDays == 0 { return "\(months)mo" }
            return "\(months)mo \(remainingDays)d"
        }
        
        let totalMonths = days / 30
        let years = totalMonths / 12
        let months = totalMonths % 12
        
        if months == 0 || (months == 11 && days % 30 > 15) || (months == 0 && days % 30 < 15) {
            let roundedYears = (months >= 11) ? years + 1 : years
            return "\(roundedYears)yr"
        }
        
        return "\(years)yr \(months)mo"
    }
    
    func statusColor(_ status: BatteryStatus) -> Color {
        switch status {
        case .critical: return .red
        case .warning: return .orange
        case .caution: return .yellow
        case .good: return .green
        }
    }
}

#Preview {
    HomeView(watches: .constant([]), showingAddWatch: .constant(false))
}
