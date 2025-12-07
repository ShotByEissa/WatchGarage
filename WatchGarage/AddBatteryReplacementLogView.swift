//
//  AddBatteryReplacementLogView.swift
//  WatchGarage
//
//  Created by Eissa Ahmad on 2025-12-07.
//


import SwiftUI

struct AddBatteryReplacementLogView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var batteryReplacementLogs: [BatteryReplacementLog]
    
    @State private var replacementDate = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("REPLACEMENT DETAILS")) {
                    DatePicker("Replacement Date", selection: $replacementDate, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Text("Add a record each time you replace the battery. The battery countdown will reset based on the most recent replacement date.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Battery Replacement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addBatteryLog()
                    }
                }
            }
        }
    }
    
    func addBatteryLog() {
        let newLog = BatteryReplacementLog(date: replacementDate, notes: notes)
        batteryReplacementLogs.append(newLog)
        dismiss()
    }
}

#Preview {
    AddBatteryReplacementLogView(batteryReplacementLogs: .constant([]))
}