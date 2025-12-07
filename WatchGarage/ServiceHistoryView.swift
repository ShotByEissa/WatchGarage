import SwiftUI

struct ServiceHistoryView: View {
    @Binding var watches: [Watch]
    @State private var editingWatchId: Int?
    
    var body: some View {
        NavigationView {
            Group {
                if watches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Watches Added")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Add a watch to track its service schedule")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(watches.sorted(by: { $0.serviceDaysRemaining < $1.serviceDaysRemaining })) { watch in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(watch.name)
                                            .font(.headline)
                                        Text(watch.model)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatTimeRemaining(watch.serviceDaysRemaining))
                                        .font(.headline)
                                        .foregroundColor(statusColor(watch.serviceStatus))
                                }
                                
                                ProgressView(value: Double(watch.serviceDaysRemaining), total: Double(watch.movementType.serviceMonths * 30))
                                    .tint(statusColor(watch.serviceStatus))
                                
                                HStack {
                                    Text(watch.movementType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if let lastService = watch.lastServiceDate {
                                        Text("Last: \(formatDate(lastService))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never serviced")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
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
                                    Text("About Service Estimates")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Service intervals are based on manufacturer recommendations and industry standards. Actual service needs vary by usage, storage, and movement quality. These are helpful reminders, not guarantees.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Service History")
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
    ServiceHistoryView(watches: .constant([]))
}
