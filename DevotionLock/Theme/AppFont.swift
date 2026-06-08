//
//  AppFont.swift
//  test1
//

import SwiftUI
import UIKit

// Stoic-style geometric sans — Inter Tight (single-story a/g, high x-height)
enum AppFont {
    enum Weight {
        case regular
        case medium
        case semibold
        case bold

        var candidates: [String] {
            switch self {
            case .regular: ["InterTight-Regular", "Inter-Regular"]
            case .medium: ["InterTight-Medium", "Inter-Medium"]
            case .semibold: ["InterTight-SemiBold", "Inter-SemiBold"]
            case .bold: ["InterTight-Bold", "Inter-Bold"]
            }
        }

        var systemWeight: Font.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semibold: .semibold
            case .bold: .bold
            }
        }
    }

    private static var resolvedNames: [Weight: String] = [:]
    private static var didResolve = false

    static var isAvailable: Bool {
        resolveIfNeeded()
        return !resolvedNames.isEmpty
    }

    static func font(size: CGFloat, weight: Weight = .regular) -> Font {
        resolveIfNeeded()
        if let name = resolvedNames[weight] {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight.systemWeight)
    }

    static func logAvailability() {
        resolveIfNeeded()
        #if DEBUG
        if resolvedNames.isEmpty {
            print("⚠️ Inter Tight not loaded — using SF Pro fallback.")
        } else {
            print("✓ Inter Tight active: \(resolvedNames)")
        }
        #endif
    }

    private static func resolveIfNeeded() {
        guard !didResolve else { return }
        didResolve = true

        for weight in [Weight.regular, .medium, .semibold, .bold] {
            for candidate in weight.candidates where UIFont(name: candidate, size: 12) != nil {
                resolvedNames[weight] = candidate
                break
            }
        }
    }
}
