import SwiftUI

struct AddWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    
    @State private var name = ""
    @State private var model = ""
    @State private var batteryInstalled = Date()
    @State private var batteryLife = 730
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Watch Details")) {
                    TextField("Name", text: $name)
                    TextField("Model", text: $model)
                }
                
                Section(header: Text("Battery Information")) {
                    DatePicker("Battery Installed", selection: $batteryInstalled, displayedComponents: .date)
                    
                    Stepper("Battery Life: \(batteryLife) days", value: $batteryLife, in: 30...3650, step: 30)
                }
            }
            .navigationTitle("Add Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addWatch()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addWatch() {
        let newId = (watches.map { $0.id }.max() ?? 0) + 1
        let newWatch = Watch(
            id: newId,
            name: name,
            model: model,
            batteryInstalled: batteryInstalled,
            batteryLife: batteryLife
        )
        watches.append(newWatch)
        dismiss()
    }
}

#Preview {
    AddWatchView(watches: .constant([]))
}
