import SwiftUI

struct AddWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    
    @State private var brand = ""
    @State private var model = ""
    @State private var firstWear = Date()
    @State private var selectedMovement: MovementType = .quartz
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH DETAILS")) {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                
                Section(header: Text("BATTERY INFO")) {
                    DatePicker("First Wear", selection: $firstWear, displayedComponents: .date)
                }
                
                Section(header: Text("MOVEMENT TYPE")) {
                    HStack {
                        Text("Movement")
                        Spacer()
                        Picker("", selection: $selectedMovement) {
                            ForEach(MovementType.allCases.filter { $0 != .custom }, id: \.self) { movement in
                                Text(movement.rawValue).tag(movement)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Typically serviced every \(selectedMovement.serviceInterval)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Section {
                    Text("Battery countdown starts from the first wear date. Standard battery life is 24 months.")
                        .font(.caption)
                        .foregroundColor(.gray)
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
            movementType: selectedMovement,
            serviceLogs: [],
            batteryReplacementLogs: []
        )
        watches.append(newWatch)
        dismiss()
    }
}

#Preview {
    AddWatchView(watches: .constant([]))
}
