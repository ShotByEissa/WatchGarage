import SwiftUI
import PhotosUI

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var croppedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WATCH PHOTO")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let image = croppedImage ?? selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.blue)
                                    .frame(width: 60, height: 60)
                            }
                            VStack(alignment: .leading) {
                                Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                    .font(.headline)
                                Text("Optional background image")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                                croppedImage = autoCropImage(image)
                            }
                        }
                    }
                }
                
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
    
    func autoCropImage(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 1083, height: 636) // 3x scale of card dimensions
        let targetAspect = targetSize.width / targetSize.height
        let imageAspect = image.size.width / image.size.height
        
        var cropRect: CGRect
        
        if imageAspect > targetAspect {
            let cropWidth = image.size.height * targetAspect
            let cropX = (image.size.width - cropWidth) / 2
            cropRect = CGRect(x: cropX, y: 0, width: cropWidth, height: image.size.height)
        } else {
            let cropHeight = image.size.width / targetAspect
            let cropY = (image.size.height - cropHeight) / 2
            cropRect = CGRect(x: 0, y: cropY, width: image.size.width, height: cropHeight)
        }
        
        guard let croppedCGImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { context in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return scaledImage
    }
    
    func addWatch() {
        let newId = (watches.map { $0.id }.max() ?? 0) + 1
        
        var customInterval: Int? = nil
        if useCustomInterval {
            if let min = Int(minYears), let max = Int(maxYears) {
                let avgYears = Double(min + max) / 2.0
                customInterval = Int(avgYears * 365.25)
            }
        }
        
        var imageName: String? = nil
        if let image = croppedImage {
            imageName = "watch_\(newId).jpg"
            saveImage(image, filename: imageName!)
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
            customServiceInterval: customInterval,
            imageName: imageName
        )
        watches.append(newWatch)
        
        NotificationManager.shared.scheduleNotifications(for: newWatch)
        saveWatches()
        dismiss()
    }
    
    func saveImage(_ image: UIImage, filename: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: fileURL)
        }
    }
}

#Preview {
    AddWatchView(watches: .constant([]), saveWatches: {})
}
