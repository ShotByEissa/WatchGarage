import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(watches: $watches)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            BatteryTrackerView(watches: $watches)
                .tabItem {
                    Label("Battery", systemImage: "bolt.fill")
                }
                .tag(1)
            
            MaintenanceTrackerView()
                .tabItem {
                    Label("Service", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)
        }
    }
}

struct BatteryTrackerView: View {
    @Binding var watches: [Watch]
    @State private var showingAddWatch = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watches.sorted(by: { $0.daysRemaining < $1.daysRemaining })) { watch in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(watch.name)
                                    .font(.headline)
                                Text(watch.model)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(formatTimeRemaining(watch.daysRemaining))
                                .foregroundColor(statusColor(watch.status))
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: Double(watch.daysRemaining), total: Double(watch.batteryLife))
                            .tint(statusColor(watch.status))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Battery Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWatch = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWatch) {
                AddWatchView(watches: $watches)
            }
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

struct MaintenanceTrackerView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "wrench.and.screwdriver")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Coming Soon")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Service History")
        }
    }
}

#Preview {
    ContentView()
}
