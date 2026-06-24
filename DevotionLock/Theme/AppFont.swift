//
//  AppFont.swift
//  test1
//
//  Inter Tight — UI sans (ABY Journal / Fabric-style). Instrument Serif — editorial headlines & paywall brand.
//

import CoreText
import SwiftUI
import UIKit

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

    enum SerifStyle {
        case regular
        case italic
    }

    private static let variablePSName = "InterTight-Regular"
    private static let serifRegularPSName = "InstrumentSerif-Regular"
    private static let serifItalicPSName = "InstrumentSerif-Italic"

    private static var resolvedNames: [Weight: String] = [:]
    private static var variableFontAvailable = false
    private static var serifRegularAvailable = false
    private static var serifItalicAvailable = false
    private static var didResolve = false

    static var isAvailable: Bool {
        resolveIfNeeded()
        return variableFontAvailable || !resolvedNames.isEmpty
    }

    static var isSerifAvailable: Bool {
        resolveIfNeeded()
        return serifRegularAvailable
    }

    static func font(size: CGFloat, weight: Weight = .regular) -> Font {
        Font(uiFont(size: size, weight: weight))
    }

    /// Editorial serif for onboarding & welcome headlines (Instrument Serif).
    static func serif(size: CGFloat, style: SerifStyle = .regular) -> Font {
        resolveIfNeeded()

        switch style {
        case .regular:
            if serifRegularAvailable, let uiFont = UIFont(name: serifRegularPSName, size: size) {
                return Font(uiFont)
            }
        case .italic:
            if serifItalicAvailable, let uiFont = UIFont(name: serifItalicPSName, size: size) {
                return Font(uiFont)
            } else if serifRegularAvailable, let uiFont = UIFont(name: serifRegularPSName, size: size) {
                let descriptor = uiFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? uiFont.fontDescriptor
                return Font(UIFont(descriptor: descriptor, size: size))
            }
        }

        return .system(size: size, design: .serif)
    }

    static func uiFont(size: CGFloat, weight: Weight = .regular) -> UIFont {
        resolveIfNeeded()

        if let name = resolvedNames[weight], let font = UIFont(name: name, size: size) {
            return font
        }

        if variableFontAvailable, let base = UIFont(name: variablePSName, size: size) {
            let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight.uiWeight]
            let descriptor = base.fontDescriptor.addingAttributes([.traits: traits])
            return UIFont(descriptor: descriptor, size: size)
        }

        return .systemFont(ofSize: size, weight: weight.uiWeight)
    }

    static func logAvailability() {
        resolveIfNeeded()
        #if DEBUG
        if variableFontAvailable || !resolvedNames.isEmpty {
            let names = resolvedNames.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
            print("✓ Inter Tight active (\(names.isEmpty ? variablePSName : names))")
            let missing = [Weight.regular, .medium, .semibold, .bold].filter { resolvedNames[$0] == nil && !variableFontAvailable }
            if !missing.isEmpty {
                print("⚠️ Inter Tight missing static weights: \(missing.map { String(describing: $0) }.joined(separator: ", "))")
            }
        } else {
            print("⚠️ Inter Tight not loaded — using SF Pro fallback.")
        }
        if serifRegularAvailable {
            print("✓ Instrument Serif active")
        } else {
            print("⚠️ Instrument Serif not loaded — using system serif fallback.")
        }
        #endif
    }

    private static func resolveIfNeeded() {
        guard !didResolve else { return }
        didResolve = true

        registerBundledFontsIfNeeded()

        variableFontAvailable = UIFont(name: variablePSName, size: 12) != nil
        serifRegularAvailable = UIFont(name: serifRegularPSName, size: 12) != nil
        serifItalicAvailable = UIFont(name: serifItalicPSName, size: 12) != nil

        for weight in [Weight.regular, .medium, .semibold, .bold] {
            for candidate in weight.candidates where UIFont(name: candidate, size: 12) != nil {
                resolvedNames[weight] = candidate
                break
            }
        }
    }

    private static func registerBundledFontsIfNeeded() {
        var urls: [URL] = []
        urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []

        var seen = Set<String>()
        for url in urls {
            let key = url.lastPathComponent
            guard seen.insert(key).inserted else { continue }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}

private extension AppFont.Weight {
    var uiWeight: UIFont.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}
