//
//  CropImageView.swift
//  WatchGarage
//
//  Created by Eissa Ahmad on 2025-12-14.
//


import SwiftUI

struct CropImageView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Card dimensions (width is screen width - 32 for padding)
    let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
    let singleCardHeight: CGFloat = 100
    let doubleCardHeight: CGFloat = 212
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // The image that user can pan/zoom
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                
                // Overlay frames showing card sizes
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Double card frame (taller - for quartz)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: cardWidth, height: doubleCardHeight)
                        .overlay(
                            Text("Double Card (Quartz)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(8),
                            alignment: .topLeading
                        )
                    
                    // Single card frame (shorter - for other movements)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: cardWidth, height: singleCardHeight)
                        .overlay(
                            Text("Single Card (Other)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(8),
                            alignment: .topLeading
                        )
                    
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Instructions at bottom
                VStack {
                    Spacer()
                    
                    Text("Pinch to zoom, drag to position")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    func cropImage() {
        // Calculate the crop rectangle based on the larger (double) card size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardWidth * 3, height: doubleCardHeight * 3))
        
        let croppedImage = renderer.image { context in
            // Create a clean canvas
            let rect = CGRect(x: 0, y: 0, width: cardWidth * 3, height: doubleCardHeight * 3)
            
            // Calculate where to draw the original image based on scale and offset
            let imageSize = image.size
            let screenSize = UIScreen.main.bounds.size
            
            // Scale factor to convert screen coordinates to image coordinates
            let scaleFactor = min(imageSize.width / screenSize.width, imageSize.height / screenSize.height)
            
            // Calculate the visible portion of the image
            let drawWidth = imageSize.width / (scale * scaleFactor)
            let drawHeight = imageSize.height / (scale * scaleFactor)
            
            let drawX = (imageSize.width - drawWidth) / 2 - (offset.width * scaleFactor / scale)
            let drawY = (imageSize.height - drawHeight) / 2 - (offset.height * scaleFactor / scale)
            
            let sourceRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
            
            if let croppedCGImage = image.cgImage?.cropping(to: sourceRect) {
                let croppedUIImage = UIImage(cgImage: croppedCGImage)
                croppedUIImage.draw(in: rect)
            }
        }
        
        onCrop(croppedImage)
    }
}