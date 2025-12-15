import SwiftUI

struct AddWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    let saveWatches: () -> Void
    
    @State private var brand = ""
    @State private var model = ""
    @State private var firstWear = Date()
    @State private var movementType: MovementType = .quartz
    @State private var useCustomInterval = false
    @State private var minYears = ""
    @State private var maxYears = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH DETAILS")) {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                
                Section(header: Text("MOVEMENT TYPE")) {
                    Picker("Movement", selection: $movementType) {
                        ForEach(MovementType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(movementType.servicingMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Toggle(isOn: $useCustomInterval) {
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.adjustable")
                                .foregroundStyle(.orange)
                            Text("Custom Service Interval")
                        }
                    }
                }
                
                // Custom interval fields - only show if toggle is on
                if useCustomInterval {
                    Section(header: Text("CUSTOM SERVICE INTERVAL")) {
                        HStack {
                            Text("Min Years")
                            Spacer()
                            TextField("2", text: $minYears)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        
                        HStack {
                            Text("Max Years")
                            Spacer()
                            TextField("3", text: $maxYears)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        
                        if let min = Int(minYears), let max = Int(maxYears), min > 0, max > 0 {
                            let avgYears = Double(min + max) / 2.0
                            Text("Average: \(String(format: "%.1f", avgYears)) years")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(header: Text("BATTERY INFO")) {
                    DatePicker("First Wear", selection: $firstWear, displayedComponents: .date)
                }
                
                Section {
                    Text("Battery countdown starts from the first wear date. Standard battery life is 24 months.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addWatch()
                    }
                    .disabled(!isFormValid())
                }
            }
        }
    }
    
    func isFormValid() -> Bool {
        if brand.isEmpty || model.isEmpty {
            return false
        }
        
        if useCustomInterval {
            guard let min = Int(minYears), let max = Int(maxYears), min > 0, max > 0 else {
                return false
            }
        }
        
        return true
    }
    
    func addWatch() {
        let newId = (watches.map { $0.id }.max() ?? 0) + 1
        
        // Calculate custom service interval if toggle is on
        var customInterval: Int? = nil
        if useCustomInterval {
            if let min = Int(minYears), let max = Int(maxYears) {
                let avgYears = Double(min + max) / 2.0
                customInterval = Int(avgYears * 365.25) // Convert years to days
            }
        }
        
        let newWatch = Watch(
            id: newId,
            name: brand,
            model: model,
            firstWear: firstWear,
            batteryLife: 730,
            movementType: movementType,
            batteryLog: [],
            serviceLog: [],
            customServiceInterval: customInterval
        )
        watches.append(newWatch)
        
        // Schedule notifications for the new watch
        NotificationManager.shared.scheduleNotifications(for: newWatch)
        
        // Save after adding
        saveWatches()
        
        dismiss()
    }
}

#Preview {
    AddWatchView(watches: .constant([]), saveWatches: {})
}
