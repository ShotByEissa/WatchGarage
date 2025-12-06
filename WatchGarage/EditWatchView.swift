import SwiftUI

struct EditWatchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var watches: [Watch]
    let watchId: Int
    
    @State private var brand: String
    @State private var model: String
    @State private var firstWear: Date
    @State private var showingDeleteAlert = false
    
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
        } else {
            _brand = State(initialValue: "")
            _model = State(initialValue: "")
            _firstWear = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH DETAILS")) {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                
                Section(header: Text("BATTERY INFO")) {
                    DatePicker("Last Battery Replacement", selection: $firstWear, displayedComponents: .date)
                }
                
                Section {
                    Text("This is when you last replaced the battery. Standard battery life is 24 months.")
                        .font(.caption)
                        .foregroundColor(.gray)
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
        }
    }
    
    func saveChanges() {
        guard let index = watchIndex else { return }
        watches[index].name = brand
        watches[index].model = model
        watches[index].firstWear = firstWear
        dismiss()
    }
    
    func deleteWatch() {
        guard let index = watchIndex else { return }
        watches.remove(at: index)
        dismiss()
    }
}
