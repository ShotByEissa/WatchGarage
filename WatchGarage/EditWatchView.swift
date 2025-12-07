import SwiftUI

struct EditWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    let watchId: Int
    
    @State private var brand: String
    @State private var model: String
    @State private var firstWear: Date
    @State private var selectedMovement: MovementType
    @State private var showingDeleteAlert = false
    @State private var showingAddServiceLog = false
    @State private var showingAddBatteryLog = false
    @State private var serviceLogs: [ServiceLog]
    @State private var batteryReplacementLogs: [BatteryReplacementLog]
    
    private var watchIndex: Int? {
        watches.firstIndex(where: { $0.id == watchId })
    }
    
    init(watches: Binding<[Watch]>, watchId: Int) {
        self._watches = watches
        self.watchId = watchId
        
        if let watch = watches.wrappedValue.first(where: { $0.id == watchId }) {
            _brand = State(initialValue: watch.name)
            _model = State(initialValue: watch.model)
            _firstWear = State(initialValue: watch.firstWear)
            _selectedMovement = State(initialValue: watch.movementType)
            _serviceLogs = State(initialValue: watch.serviceLogs)
            _batteryReplacementLogs = State(initialValue: watch.batteryReplacementLogs)
        } else {
            _brand = State(initialValue: "")
            _model = State(initialValue: "")
            _firstWear = State(initialValue: Date())
            _selectedMovement = State(initialValue: .quartz)
            _serviceLogs = State(initialValue: [])
            _batteryReplacementLogs = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH DETAILS")) {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                
                if selectedMovement.needsBatteryTracking {
                    Section(header: HStack {
                        Text("BATTERY REPLACEMENT LOG")
                        Spacer()
                        Button(action: {
                            showingAddBatteryLog = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }) {
                        if batteryReplacementLogs.isEmpty {
                            Text("No battery replacements recorded")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(batteryReplacementLogs.sorted(by: { $0.date > $1.date })) { log in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatDate(log.date))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !log.notes.isEmpty {
                                        Text(log.notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteBatteryLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("SERVICE LOG")
                    Spacer()
                    Button(action: {
                        showingAddServiceLog = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }) {
                    if serviceLogs.isEmpty {
                        Text("No service records")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(serviceLogs.sorted(by: { $0.date > $1.date })) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(log.date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if !log.notes.isEmpty {
                                    Text(log.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteServiceLog(log)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section {
                    if selectedMovement.needsBatteryTracking {
                        Text("Battery countdown resets based on the most recent battery replacement. Service countdown resets based on the most recent service.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Service countdown resets based on the most recent service.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Watch")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(brand.isEmpty || model.isEmpty)
                }
            }
            .alert("Delete Watch?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWatch()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showingAddServiceLog) {
                AddServiceLogView(serviceLogs: $serviceLogs)
            }
            .sheet(isPresented: $showingAddBatteryLog) {
                AddBatteryReplacementLogView(batteryReplacementLogs: $batteryReplacementLogs)
            }
        }
    }
    
    func saveChanges() {
        guard let index = watchIndex else { return }
        watches[index].name = brand
        watches[index].model = model
        watches[index].firstWear = firstWear
        watches[index].serviceLogs = serviceLogs
        watches[index].batteryReplacementLogs = batteryReplacementLogs
        dismiss()
    }
    
    func deleteWatch() {
        guard let index = watchIndex else { return }
        watches.remove(at: index)
        dismiss()
    }
    
    func deleteServiceLog(_ log: ServiceLog) {
        serviceLogs.removeAll { $0.id == log.id }
    }
    
    func deleteBatteryLog(_ log: BatteryReplacementLog) {
        batteryReplacementLogs.removeAll { $0.id == log.id }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
