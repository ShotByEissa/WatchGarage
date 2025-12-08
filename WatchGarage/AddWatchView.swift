import SwiftUI

struct AddWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    
    @State private var brand = ""
    @State private var model = ""
    @State private var firstWear = Date()
    @State private var movementType: MovementType = .quartz
    
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
                    .disabled(brand.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    func addWatch() {
        let newId = (watches.map { $0.id }.max() ?? 0) + 1
        let newWatch = Watch(
            id: newId,
            name: brand,
            model: model,
            firstWear: firstWear,
            batteryLife: 730,
            movementType: movementType,
            batteryLog: [],
            serviceLog: []
        )
        watches.append(newWatch)
        dismiss()
    }
}

#Preview {
    AddWatchView(watches: .constant([]))
}
