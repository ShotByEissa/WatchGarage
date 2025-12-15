import SwiftUI
import PhotosUI

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImageDeleteAlert = false
    
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
                // Watch Photo Section
                Section(header: Text("WATCH PHOTO")) {
                    if let backgroundImage = watch?.backgroundImage {
                        HStack {
                            Image(uiImage: backgroundImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text("Background Image")
                                    .font(.headline)
                                Text("Tap to change or remove")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                showingImageDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.blue)
                                    .frame(width: 60, height: 60)
                                
                                VStack(alignment: .leading) {
                                    Text("Add Photo")
                                        .font(.headline)
                                    Text("Optional background image")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    if watch?.backgroundImage != nil {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundStyle(.blue)
                                Text("Change Photo")
                            }
                        }
                    }
                }
                .onChange(of: selectedPhoto) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            updateWatchImage(image)
                        }
                    }
                }
                
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
            .alert("Remove Photo?", isPresented: $showingImageDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    removeWatchImage()
                }
            } message: {
                Text("This will remove the background image from this watch card.")
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
    
    func autoCropImage(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 1083, height: 636)
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
    
    func updateWatchImage(_ image: UIImage) {
        guard let index = watchIndex else { return }
        
        let croppedImage = autoCropImage(image)
        
        if let oldImageName = watches[index].imageName {
            deleteImageFile(oldImageName)
        }
        
        let newImageName = "watch_\(watches[index].id).jpg"
        saveImage(croppedImage, filename: newImageName)
        
        watches[index].imageName = newImageName
        saveWatches()
        refreshTrigger = UUID()
    }
    
    func removeWatchImage() {
        guard let index = watchIndex else { return }
        
        if let imageName = watches[index].imageName {
            deleteImageFile(imageName)
        }
        
        watches[index].imageName = nil
        saveWatches()
        refreshTrigger = UUID()
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
    
    func deleteImageFile(_ filename: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
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
        NotificationManager.shared.scheduleNotifications(for: watches[wIndex])
        saveWatches()
        refreshTrigger = UUID()
    }
    
    func deleteWatch() {
        guard let index = watchIndex else { return }
        
        if let imageName = watches[index].imageName {
            deleteImageFile(imageName)
        }
        
        NotificationManager.shared.cancelNotifications(for: watches[index])
        watches.remove(at: index)
        saveWatches()
        dismiss()
    }
}
