//
//  SolarDuotoneIcons.swift
//  DevotionLock
//
//  Solar Icon Set — Bold Duotone (480 Design), CC BY 4.0.
//  Attribution: https://github.com/480-Design/Solar-icon-set
//  Source SVGs: DevotionLock/Resources/SolarDuotone/
//

import SwiftUI

/// Solar Bold Duotone icons for the Clean Home experiment.
/// Each glyph composites a secondary (soft) layer under a primary (solid) layer.
enum SolarDuotone {
    enum Icon: String, CaseIterable {
        case home
        case chat
        case profile
        case chaplain
        case journal
        case scripture
        case prayer
        case flame
        case cloud
        case close
        case stars

        fileprivate var assetStem: String {
            "Solar" + rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    struct Glyph: View {
        let icon: Icon
        var size: CGFloat = 24
        /// Solid / foreground layer (Solar primary paths).
        var primary: Color = CleanDesign.Color.accent
        /// Soft / background layer (Solar opacity-.5 paths).
        var secondary: Color = CleanDesign.Color.accentSoft

        var body: some View {
            ZStack {
                Image("\(icon.assetStem)Secondary")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(secondary)
                Image("\(icon.assetStem)Primary")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(primary)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
        }
    }
}
