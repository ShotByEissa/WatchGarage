import SwiftUI

struct ContentView: View {
    @State private var showingAddWatch = false
    @State private var watches: [Watch] = []
    
    var body: some View {
        WatchTrackerView(watches: $watches, showingAddWatch: $showingAddWatch, saveWatches: saveWatches)
            .sheet(isPresented: $showingAddWatch) {
                AddWatchView(watches: $watches, saveWatches: saveWatches)
            }
            .onAppear {
                loadWatches()
            }
    }
    
    func loadWatches() {
        if let data = UserDefaults.standard.data(forKey: "watches") {
            if let decoded = try? JSONDecoder().decode([Watch].self, from: data) {
                watches = decoded
            }
        }
    }
    
    func saveWatches() {
        if let encoded = try? JSONEncoder().encode(watches) {
            UserDefaults.standard.set(encoded, forKey: "watches")
        }
    }
}

struct WatchTrackerView: View {
    @Binding var watches: [Watch]
    @Binding var showingAddWatch: Bool
    @State private var editingWatchId: Int?
    @State private var lastRefresh = Date()
    let saveWatches: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // Last Updated Section
                    Section {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text("Last updated: \(lastRefresh, style: .time) on \(lastRefresh, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    
                    ForEach(watches.sorted(by: {
                        min($0.daysUntilBattery, $0.daysUntilService) < min($1.daysUntilBattery, $1.daysUntilService)
                    })) { watch in
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(watch.name)
                                    .font(.headline)
                                Text(watch.model)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            // Battery Progress (only for quartz)
                            if watch.movementType == .quartz {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Battery")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(formatTimeRemaining(watch.daysUntilBattery))
                                            .font(.caption)
                                            .foregroundStyle(statusColor(watch.batteryStatus))
                                            .fontWeight(.semibold)
                                    }
                                    ProgressView(value: max(0, Double(watch.daysUntilBattery)), total: Double(watch.batteryLife))
                                        .tint(statusColor(watch.batteryStatus))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                }
                            }
                            
                            // Service Progress (all watches)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Service")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(formatTimeRemaining(watch.daysUntilService))
                                        .font(.caption)
                                        .foregroundStyle(statusColor(watch.serviceStatus))
                                        .fontWeight(.semibold)
                                }
                                ProgressView(value: max(0, Double(watch.daysUntilService)), total: Double(watch.serviceInterval))
                                    .tint(statusColor(watch.serviceStatus))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                            }
                        }
                        .padding(.vertical, 12)
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
                                    .foregroundStyle(.secondary)
                                Text("About Maintenance Estimates")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Battery and service estimates are based on manufacturer recommendations and average usage patterns. Actual intervals vary by wear frequency, storage conditions, and individual watch characteristics. These are helpful reminders, not guarantees.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    
                    // Spacer for floating button
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
                .navigationTitle("Watch Garage")
                .refreshable {
                    refreshData()
                }
                .onAppear {
                    refreshData()
                }
                .sheet(item: Binding(
                    get: { editingWatchId.map { WatchIdentifier(id: $0) } },
                    set: { editingWatchId = $0?.id }
                )) { identifier in
                    EditWatchView(watches: $watches, watchId: identifier.id, saveWatches: saveWatches)
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddWatch = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(.orange))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    func refreshData() {
        lastRefresh = Date()
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
