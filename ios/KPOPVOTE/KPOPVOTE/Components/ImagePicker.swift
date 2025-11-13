//
//  ImagePicker.swift
//  KPOPVOTE
//
//  Image picker component for selecting cover images
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    let placeholder: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat

    init(
        selectedImage: Binding<UIImage?>,
        placeholder: String = "画像を選択",
        maxWidth: CGFloat = .infinity,
        maxHeight: CGFloat = 200
    ) {
        self._selectedImage = selectedImage
        self.placeholder = placeholder
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }

    var body: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                // Show selected image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                // Remove button
                Button(action: {
                    selectedImage = nil
                    selectedItem = nil
                }) {
                    Label("画像を削除", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                // Show picker button
                PhotosPicker(selection: $selectedItem,
                           matching: .images,
                           photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text(placeholder)
                    }
                    .frame(maxWidth: maxWidth, minHeight: 100)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

// MARK: - Preview
struct ImagePicker_Previews: PreviewProvider {
    @State static var image: UIImage? = nil

    static var previews: some View {
        VStack(spacing: 20) {
            Text("カバー画像選択")
                .font(.headline)

            ImagePicker(
                selectedImage: $image,
                placeholder: "タスクのカバー画像を選択"
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
