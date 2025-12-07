import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingAddWatch = false
    @State private var watches: [Watch] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(watches: $watches, showingAddWatch: $showingAddWatch)
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
        .sheet(isPresented: $showingAddWatch) {
            AddWatchView(watches: $watches)
        }
    }
}

struct BatteryTrackerView: View {
    @Binding var watches: [Watch]
    @State private var editingWatchId: Int?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
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
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                editingWatchId = watch.id
                            } label: {
                                Label("Edit Watch", systemImage: "pencil")
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("About Battery Estimates")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Battery life estimates are based on average global usage patterns. Actual battery life varies depending on how often you wear your watch, storage conditions, and other factors. These predictions are meant as helpful reminders, not guarantees.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Battery Tracker")
            .sheet(item: Binding(
                get: { editingWatchId.map { WatchIdentifier(id: $0) } },
                set: { editingWatchId = $0?.id }
            )) { identifier in
                EditWatchView(watches: $watches, watchId: identifier.id)
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

struct WatchIdentifier: Identifiable {
    let id: Int
}

struct MaintenanceTrackerView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Coming Soon")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Service History")
        }
    }
}

#Preview {
    ContentView()
}
