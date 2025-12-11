import SwiftUI

struct EditWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    let watchId: Int
    let saveWatches: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingBatteryDatePicker = false
    @State private var showingServiceDatePicker = false
    @State private var newBatteryDate = Date()
    @State private var newServiceDate = Date()
    @State private var refreshTrigger = UUID()
    
    private var watchIndex: Int? {
        watches.firstIndex(where: { $0.id == watchId })
    }
    
    private var watch: Watch? {
        guard let index = watchIndex else { return nil }
        return watches[index]
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH DETAILS")) {
                    HStack {
                        Text("Brand")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(watch?.name ?? "")
                    }
                    HStack {
                        Text("Model")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(watch?.model ?? "")
                    }
                    HStack {
                        Text("Movement")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(watch?.movementType.rawValue ?? "")
                    }
                    HStack {
                        Text("First Wear")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let firstWear = watch?.firstWear {
                            Text(firstWear, style: .date)
                        }
                    }
                }
                
                // Battery Log - Only for Quartz
                if watch?.movementType == .quartz {
                    Section(header: Text("BATTERY LOG")) {
                        Button(action: {
                            newBatteryDate = Date()
                            showingBatteryDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Log Battery Replacement")
                            }
                        }
                        
                        if let batteryLog = watch?.batteryLog, !batteryLog.isEmpty {
                            ForEach(Array(batteryLog.sorted(by: >).enumerated()), id: \.offset) { index, date in
                                HStack {
                                    Text(date, style: .date)
                                    Spacer()
                                    Text(date, style: .time)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete { indexSet in
                                deleteBatteryLog(at: indexSet)
                            }
                        } else {
                            Text("No battery replacements logged")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Service Log - For ALL watches
                Section(header: Text("SERVICE LOG")) {
                    Button(action: {
                        newServiceDate = Date()
                        showingServiceDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Log Service")
                        }
                    }
                    
                    if let serviceLog = watch?.serviceLog, !serviceLog.isEmpty {
                        ForEach(Array(serviceLog.sorted(by: >).enumerated()), id: \.offset) { index, date in
                            HStack {
                                Text(date, style: .date)
                                Spacer()
                                Text(date, style: .time)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            deleteServiceLog(at: indexSet)
                        }
                    } else {
                        Text("No services logged")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
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
            .id(refreshTrigger)
            .navigationTitle("Watch Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
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
            .sheet(isPresented: $showingBatteryDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker("Battery Replacement Date", selection: $newBatteryDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Log Battery Replacement")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingBatteryDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                if let index = watchIndex {
                                    watches[index].batteryLog.append(newBatteryDate)
                                    // Reschedule notifications with updated battery log
                                    NotificationManager.shared.scheduleNotifications(for: watches[index])
                                    saveWatches()
                                    refreshTrigger = UUID()
                                }
                                showingBatteryDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingServiceDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker("Service Date", selection: $newServiceDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Log Service")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingServiceDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                if let index = watchIndex {
                                    watches[index].serviceLog.append(newServiceDate)
                                    // Reschedule notifications with updated service log
                                    NotificationManager.shared.scheduleNotifications(for: watches[index])
                                    saveWatches()
                                    refreshTrigger = UUID()
                                }
                                showingServiceDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    func deleteBatteryLog(at offsets: IndexSet) {
        guard let wIndex = watchIndex else { return }
        let sortedLog = watches[wIndex].batteryLog.sorted(by: >)
        for offset in offsets {
            let dateToRemove = sortedLog[offset]
            if let logIndex = watches[wIndex].batteryLog.firstIndex(of: dateToRemove) {
                watches[wIndex].batteryLog.remove(at: logIndex)
            }
        }
        // Reschedule notifications after deleting log entry
        NotificationManager.shared.scheduleNotifications(for: watches[wIndex])
        saveWatches()
        refreshTrigger = UUID()
    }
    
    func deleteServiceLog(at offsets: IndexSet) {
        guard let wIndex = watchIndex else { return }
        let sortedLog = watches[wIndex].serviceLog.sorted(by: >)
        for offset in offsets {
            let dateToRemove = sortedLog[offset]
            if let logIndex = watches[wIndex].serviceLog.firstIndex(of: dateToRemove) {
                watches[wIndex].serviceLog.remove(at: logIndex)
            }
        }
        // Reschedule notifications after deleting log entry
        NotificationManager.shared.scheduleNotifications(for: watches[wIndex])
        saveWatches()
        refreshTrigger = UUID()
    }
    
    func deleteWatch() {
        guard let index = watchIndex else { return }
        // Cancel all notifications for this watch before deleting
        NotificationManager.shared.cancelNotifications(for: watches[index])
        watches.remove(at: index)
        saveWatches()
        dismiss()
    }
}
