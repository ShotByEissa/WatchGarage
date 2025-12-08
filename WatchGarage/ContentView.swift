import SwiftUI

struct ContentView: View {
    @State private var showingAddWatch = false
    @State private var watches: [Watch] = []
    
    var body: some View {
        WatchTrackerView(watches: $watches, showingAddWatch: $showingAddWatch)
            .sheet(isPresented: $showingAddWatch) {
                AddWatchView(watches: $watches)
            }
    }
}

struct WatchTrackerView: View {
    @Binding var watches: [Watch]
    @Binding var showingAddWatch: Bool
    @State private var editingWatchId: Int?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watches.sorted(by: {
                    min($0.daysUntilBattery, $0.daysUntilService) < min($1.daysUntilBattery, $1.daysUntilService)
                })) { watch in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(watch.name)
                                    .font(.headline)
                                Text(watch.model)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        // Battery Progress (only for quartz)
                        if watch.movementType == .quartz {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Battery")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatTimeRemaining(watch.daysUntilBattery))
                                        .font(.caption)
                                        .foregroundColor(statusColor(watch.batteryStatus))
                                        .fontWeight(.semibold)
                                }
                                ProgressView(value: max(0, Double(watch.daysUntilBattery)), total: Double(watch.batteryLife))
                                    .tint(statusColor(watch.batteryStatus))
                            }
                        }
                        
                        // Service Progress (all watches)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Service")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatTimeRemaining(watch.daysUntilService))
                                    .font(.caption)
                                    .foregroundColor(statusColor(watch.serviceStatus))
                                    .fontWeight(.semibold)
                            }
                            ProgressView(value: max(0, Double(watch.daysUntilService)), total: Double(watch.serviceInterval))
                                .tint(statusColor(watch.serviceStatus))
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            editingWatchId = watch.id
                        } label: {
                            Label("Edit Watch", systemImage: "pencil")
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("About Maintenance Estimates")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Battery and service estimates are based on manufacturer recommendations and average usage patterns. Actual intervals vary by wear frequency, storage conditions, and individual watch characteristics. These are helpful reminders, not guarantees.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Watch Garage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWatch = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
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

#Preview {
    ContentView()
}
