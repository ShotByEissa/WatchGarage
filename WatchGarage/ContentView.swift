import SwiftUI

struct ContentView: View {
    @State private var watches: [Watch] = [
        Watch(id: 1, name: "Seiko SKX007", model: "Diver's Watch",
              firstWear: Calendar.current.date(byAdding: .day, value: -585, to: Date())!,
              batteryLife: 730),
        Watch(id: 2, name: "Casio G-Shock", model: "DW-5600E",
              firstWear: Calendar.current.date(byAdding: .day, value: -685, to: Date())!,
              batteryLife: 730),
        Watch(id: 3, name: "Timex Weekender", model: "Chronograph",
              firstWear: Calendar.current.date(byAdding: .day, value: -150, to: Date())!,
              batteryLife: 730),
        Watch(id: 4, name: "Citizen Eco-Drive", model: "BM8180-03E",
              firstWear: Calendar.current.date(byAdding: .day, value: -718, to: Date())!,
              batteryLife: 730)
    ]
    
    @State private var showingAddWatch = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watches.sorted(by: { $0.daysRemaining < $1.daysRemaining })) { watch in
                    WatchRow(watch: watch)
                }
            }
            .navigationTitle("Battery Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWatch = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddWatch) {
                AddWatchView(watches: $watches)
            }
        }
    }
}

struct WatchRow: View {
    let watch: Watch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(watch.name)
                        .font(.headline)
                    Text(watch.model)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(formatTimeRemaining(watch.daysRemaining))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(watch.status))
                    .cornerRadius(8)
            }
            
            ProgressView(value: Double(watch.daysRemaining), total: Double(watch.batteryLife))
                .tint(statusColor(watch.status).opacity(0.6))
        }
        .padding(.vertical, 4)
    }
    
    func formatTimeRemaining(_ days: Int) -> String {
        if days < 0 { return "OVERDUE" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        
        let months = days / 30
        let remainingDays = days % 30
        
        if days < 365 {
            if remainingDays == 0 { return "\(months)mo" }
            return "\(months)mo \(remainingDays)d"
        }
        
        let years = days / 365
        let remainingMonths = (days % 365) / 30
        if remainingMonths == 0 { return "\(years)yr" }
        return "\(years)yr \(remainingMonths)mo"
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
    ContentView()
}
