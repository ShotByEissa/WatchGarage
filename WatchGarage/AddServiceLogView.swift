//
//  AddServiceLogView.swift
//  WatchGarage
//
//  Created by Eissa Ahmad on 2025-12-07.
//


import SwiftUI

struct AddServiceLogView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var serviceLogs: [ServiceLog]
    
    @State private var serviceDate = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("SERVICE DETAILS")) {
                    DatePicker("Service Date", selection: $serviceDate, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Text("Add a record each time your watch is serviced. The service countdown will reset based on the most recent service date.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Service Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addServiceLog()
                    }
                }
            }
        }
    }
    
    func addServiceLog() {
        let newLog = ServiceLog(date: serviceDate, notes: notes)
        serviceLogs.append(newLog)
        dismiss()
    }
}

#Preview {
    AddServiceLogView(serviceLogs: .constant([]))
}