//
//  PhotoPicker.swift
//  TimeProgressTracker
//
//  Simple photo picker wrapper (iOS 14+)
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else {
                parent.onComplete?()
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    guard let uiImage = image as? UIImage else {
                        DispatchQueue.main.async {
                            self.parent.onComplete?()
                        }
                        return
                    }

                    let jpegData = uiImage.jpegData(compressionQuality: 0.8)
                    DispatchQueue.main.async {
                        self.parent.imageData = jpegData
                        self.parent.onComplete?()
                    }
                }
            } else {
                parent.onComplete?()
            }
        }
    }
}
