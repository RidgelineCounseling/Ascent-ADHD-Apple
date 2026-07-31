//
//  Theme.swift
//  Ascent ADHD
//
//  Design system ported from the Android app (MainActivity.kt palette + typography).
//
//  Design rules (mirrors the Android CLAUDE.md — do not drift):
//   • Colors: reuse the named constants below. Do NOT invent new hex values for a one-off;
//     pick the closest existing constant.
//   • Type: use the AscentFont role helpers (a 1:1 map of the Material typography scale).
//     Weight/emphasis via .fontWeight inline.
//   • Icons: SF Symbols, "outline" weight for essentially everything; a filled symbol
//     (checkmark.circle.fill) is reserved for done/active states.
//

import SwiftUI

// MARK: - Hex helper

extension Color {
    /// Build a Color from a 0xAARRGGBB or 0xRRGGBB integer (matches the Android Color(0x…) literals).
    init(argb: UInt32) {
        let hasAlpha = argb > 0xFF_FF_FF
        let a = hasAlpha ? Double((argb >> 24) & 0xFF) / 255.0 : 1.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// The packed 0xAARRGGBB value — used to persist a swatch choice the way the Android app does.
    var argb: UInt32 {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32((r * 255).rounded()) & 0xFF
        let gi = UInt32((g * 255).rounded()) & 0xFF
        let bi = UInt32((b * 255).rounded()) & 0xFF
        let ai = UInt32((a * 255).rounded()) & 0xFF
        return (ai << 24) | (ri << 16) | (gi << 8) | bi
        #else
        return 0xFFFFFFFF
        #endif
    }
}

// MARK: - Palette
//
// Brand names preserved so references read like the Android source. Hex values are identical.

let Navy = Color(argb: 0xFF1C2F45)            // Logo / nav structure (unselected nav icons)
let RidgelineBlue = Color(argb: 0xFF3366FF)   // Buttons / links / interactive
let SkyMid = Color(argb: 0xFF185FA5)          // Button hover / text on ice
let SkyDark = Color(argb: 0xFF0C447C)         // Text on ice (darker)
let MidnightSlate = Color(argb: 0xFF000033)   // Primary text (deep navy) + elevation visuals
let MistBlue = Color(argb: 0xFFA3B8C9)        // Muted blue-gray (external events, outline)
let SkyGray = Color(argb: 0xFFEFF2F1)         // App background (Platinum)
let CardInset = Color(argb: 0xFFF7F9F8)       // Gentle inset fills (text boxes, subcards)
let PureWhite = Color(argb: 0xFFFFFFFF)       // Card surfaces
let PureBlack = Color(argb: 0xFF000000)
let SuccessGreen = Color(argb: 0xFF00A878)    // Completed tasks / streaks (Jungle Green)
let IceBlueAccent = Color(argb: 0xFFE6F1FB)   // Selected states / highlights (ice)
let SoftYellow = Color(argb: 0xFFFDE68A)      // Priority placement blocks

// Completion (green) + overdue (red) role colors.
let TealLight = Color(argb: 0xFFE1F5EE)       // Completion chip background
let TealDark = Color(argb: 0xFF085041)        // Text on completion chip
let OverdueRed = Color(argb: 0xFFEF233C)      // Overdue tasks
let OverdueRedLight = Color(argb: 0xFFFCEBEB) // Overdue chip background
let OverdueRedDark = Color(argb: 0xFFA32D2D)  // Text on red light

// Neutral text + border tiers.
let BorderGray = Color(argb: 0xFFD3D1C7)      // Dividers / card borders
let TextMuted = Color(argb: 0xFF5F5E5A)       // Secondary / label text
let TextHint = Color(argb: 0xFF888780)        // Placeholders / tertiary
let NeutralFill = Color(argb: 0xFFF1EFE8)     // Neutral chip / inset row fill

// Metric colors (elevation / scoreboard climbing theme).
let MetricGold = Color(argb: 0xFFD4AF37)
let MetricGreen = Color(argb: 0xFF10B981)
let MetricOrange = Color(argb: 0xFFF97316)
let MetricBlue = Color(argb: 0xFF2563EB)

// Surface-container roles (Material 3 tonal surfaces the Android app pulls from the color scheme).
// Approximated as light tints of the platinum background so cards read the same.
let SurfaceContainerLow = Color(argb: 0xFFFFFFFF)
let SurfaceContainerHigh = Color(argb: 0xFFF3F5F4)

// Event block palette — the curated, harmonized set. Index 0 (white) = "None / default".
let EventColors: [Color] = [
    PureWhite,                 // None / default (no fill)
    Color(argb: 0xFF9DB4F2),   // Periwinkle
    Color(argb: 0xFF8ECFB6),   // Jade
    Color(argb: 0xFF8FC7D2),   // Soft teal
    Color(argb: 0xFFE8CF92),   // Warm sand
    Color(argb: 0xFFE8AC93),   // Soft clay
    Color(argb: 0xFFDBA6BF),   // Dusty rose
    Color(argb: 0xFFB8ABDD),   // Heather
    Color(argb: 0xFFB5C2CF)    // Cool stone
]

// MARK: - Typography
//
// A 1:1 map of the Android RidgelineTypography scale. Headings (title/headline/display) used a
// Plus Jakarta Sans face and body used Inter; here we approximate with the system font (rounded
// for headings) so nothing needs bundling. Sizes and weights match the original.

enum AscentFont {
    static let displayLarge  = Font.system(size: 36, weight: .semibold, design: .rounded)
    static let displayMedium = Font.system(size: 30, weight: .semibold, design: .rounded)
    static let displaySmall  = Font.system(size: 26, weight: .semibold, design: .rounded)

    static let headlineLarge  = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headlineSmall  = Font.system(size: 20, weight: .semibold, design: .rounded)

    static let titleLarge  = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let titleMedium = Font.system(size: 16, weight: .medium, design: .rounded)
    static let titleSmall  = Font.system(size: 14, weight: .medium, design: .rounded)

    static let bodyLarge  = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall  = Font.system(size: 12, weight: .regular)

    static let labelLarge  = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall  = Font.system(size: 11, weight: .medium)
}

// Corner radii used across cards/pills (mirrors RidgelineShapes + inline RoundedCornerShape use).
enum AscentRadius {
    static let card: CGFloat = 12
    static let cardLarge: CGFloat = 16
    static let pill: CGFloat = 999
}
