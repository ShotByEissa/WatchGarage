import SwiftUI

struct ContentView: View {
    @State private var showingAddWatch = false
    @State private var watches: [Watch] = []
    @State private var viewId = UUID()
    
    var body: some View {
        WatchTrackerView(watches: $watches, showingAddWatch: $showingAddWatch, saveWatchesOnly: saveWatchesOnly, forceRefresh: forceRefresh)
            .id(viewId)
            .sheet(isPresented: $showingAddWatch) {
                AddWatchView(watches: $watches, saveWatches: saveWatchesOnly)
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
    
    func saveWatchesOnly() {
        if let encoded = try? JSONEncoder().encode(watches) {
            UserDefaults.standard.set(encoded, forKey: "watches")
        }
    }
    
    func forceRefresh() {
        viewId = UUID()
    }
}

struct WatchTrackerView: View {
    @Binding var watches: [Watch]
    @Binding var showingAddWatch: Bool
    @State private var editingWatchId: Int?
    @State private var lastRefresh = Date()
    let saveWatchesOnly: () -> Void
    let forceRefresh: () -> Void
    
    var sortedWatches: [Watch] {
        watches.sorted(by: {
            min($0.daysUntilBattery, $0.daysUntilService) < min($1.daysUntilBattery, $1.daysUntilService)
        })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header Cards Row
                    HStack(spacing: 12) {
                        // Last Updated Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text("Last Updated")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(lastRefresh, style: .time)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(lastRefresh, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // About Estimates Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text("About Estimates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Based on manufacturer specs and average usage.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .frame(height: 100)
                    
                    // Conditional Layout - Grid for 2+, Full-width for 1
                    if sortedWatches.count == 1 {
                        // Single full-width card
                        if let watch = sortedWatches.first {
                            WatchCard(watch: watch, isQuartz: watch.movementType == .quartz)
                                .onTapGesture {
                                    editingWatchId = watch.id
                                }
                        }
                    } else {
                        // Two Column Grid for multiple watches
                        TwoColumnMasonryView(
                            watches: sortedWatches,
                            onTap: { watchId in
                                editingWatchId = watchId
                            }
                        )
                    }
                    
                    // Bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Watch Garage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWatch = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                refreshData()
            }
            .sheet(item: Binding(
                get: { editingWatchId.map { WatchIdentifier(id: $0) } },
                set: {
                    if $0 == nil {
                        // Sheet was dismissed, force refresh
                        forceRefresh()
                    }
                    editingWatchId = $0?.id
                }
            )) { identifier in
                EditWatchView(watches: $watches, watchId: identifier.id, saveWatches: saveWatchesOnly)
            }
        }
    }
    
    func refreshData() {
        lastRefresh = Date()
    }
}

struct TwoColumnMasonryView: View {
    let watches: [Watch]
    let onTap: (Int) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left Column
            VStack(spacing: 12) {
                ForEach(leftColumnWatches) { watch in
                    WatchCard(watch: watch, isQuartz: watch.movementType == .quartz)
                        .onTapGesture {
                            onTap(watch.id)
                        }
                }
            }
            
            // Right Column
            VStack(spacing: 12) {
                ForEach(rightColumnWatches) { watch in
                    WatchCard(watch: watch, isQuartz: watch.movementType == .quartz)
                        .onTapGesture {
                            onTap(watch.id)
                        }
                }
            }
        }
    }
    
    var leftColumnWatches: [Watch] {
        distributeWatches().0
    }
    
    var rightColumnWatches: [Watch] {
        distributeWatches().1
    }
    
    func distributeWatches() -> ([Watch], [Watch]) {
        var left: [Watch] = []
        var right: [Watch] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        
        for watch in watches {
            let cardHeight: CGFloat = watch.movementType == .quartz ? 212 : 100
            
            if leftHeight <= rightHeight {
                left.append(watch)
                leftHeight += cardHeight + 12
            } else {
                right.append(watch)
                rightHeight += cardHeight + 12
            }
        }
        
        return (left, right)
    }
}

struct WatchCard: View {
    let watch: Watch
    let isQuartz: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Watch Name at top
            VStack(alignment: .leading, spacing: 2) {
                Text(watch.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(watch.model)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Push everything down
            Spacer(minLength: 0)
            
            // Progress bars at bottom
            VStack(alignment: .leading, spacing: 8) {
                // Battery Progress (only for quartz)
                if isQuartz {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "battery.25")
                                .foregroundStyle(statusColor(watch.batteryStatus))
                                .font(.caption)
                            Text("Battery")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatTimeRemaining(watch.daysUntilBattery))
                                .font(.caption)
                                .foregroundStyle(statusColor(watch.batteryStatus))
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: max(0, Double(watch.daysUntilBattery)), total: Double(watch.batteryLife))
                            .tint(statusColor(watch.batteryStatus))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    }
                }
                
                // Service Progress (all watches)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(statusColor(watch.serviceStatus))
                            .font(.caption)
                        Text("Service")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatTimeRemaining(watch.daysUntilService))
                            .font(.caption)
                            .foregroundStyle(statusColor(watch.serviceStatus))
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: max(0, Double(watch.daysUntilService)), total: Double(watch.serviceInterval))
                        .tint(statusColor(watch.serviceStatus))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: isQuartz ? 212 : 100, alignment: .top)
        .background(
            ZStack {
                Color(.systemGray6)
                
                if let backgroundImage = watch.backgroundImage {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0.08)
                }
            }
        )
        .cornerRadius(12)
        .clipped()
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
