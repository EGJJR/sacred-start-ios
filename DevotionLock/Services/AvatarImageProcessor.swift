//
//  AvatarImageProcessor.swift
//  DevotionLock
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct AvatarPickerImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            AvatarPickerImage(data: data)
        }
    }
}

enum AvatarImageProcessor {
    static func jpegData(from data: Data, maxDimension: CGFloat = 1024, compressionQuality: CGFloat = 0.85) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let size = image.size
        let largest = max(size.width, size.height)
        let scale = min(1, maxDimension / largest)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized.jpegData(compressionQuality: compressionQuality)
    }
}
