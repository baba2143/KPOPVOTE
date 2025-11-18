//
//  ImagePicker.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Image Picker Component
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("❌ [ImagePicker] Failed to load image: \(error)")
                        return
                    }

                    guard let uiImage = image as? UIImage else {
                        print("❌ [ImagePicker] Invalid image format")
                        return
                    }

                    DispatchQueue.main.async {
                        // Resize image to max 1024x1024
                        self.parent.selectedImage = self.resizeImage(uiImage, maxDimension: 1024)
                        print("✅ [ImagePicker] Image selected and resized")
                    }
                }
            }
        }

        private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size
            let aspectRatio = size.width / size.height

            var newSize: CGSize
            if size.width > size.height {
                newSize = CGSize(width: min(size.width, maxDimension),
                               height: min(size.width, maxDimension) / aspectRatio)
            } else {
                newSize = CGSize(width: min(size.height, maxDimension) * aspectRatio,
                               height: min(size.height, maxDimension))
            }

            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
}
