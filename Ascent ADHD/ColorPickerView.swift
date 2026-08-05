//
//  ColorPickerView.swift
//  Ascent ADHD
//
//  A self-contained HSV color picker (rainbow reference bar + hue/saturation/brightness sliders +
//  live preview and hex), ported from CustomColorPickerDialog. Returns a Color the caller stores as
//  an ARGB int like the preset swatches.
//

import SwiftUI

struct CustomColorPicker: View {
    @Environment(\.dismiss) private var dismiss
    let initial: Color
    let onConfirm: (Color) -> Void

    @State private var hue: Double = 0.5
    @State private var sat: Double = 0.6
    @State private var bright: Double = 0.8

    private var preview: Color { Color(hue: hue, saturation: sat, brightness: bright) }

    private var hexString: String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(preview).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return "#—"
        #endif
    }

    private let rainbow: [Color] = (0...12).map { Color(hue: Double($0) / 12.0, saturation: 1, brightness: 1) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12).fill(preview)
                        .frame(width: 48, height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BorderGray, lineWidth: 1))
                    Text(hexString).font(AscentFont.titleSmall).foregroundColor(MidnightSlate)
                }

                Text("Hue").font(AscentFont.labelMedium).foregroundColor(TextMuted)
                LinearGradient(colors: rainbow, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 10).clipShape(Capsule())
                Slider(value: $hue, in: 0...1).tint(RidgelineBlue)

                Text("Saturation").font(AscentFont.labelMedium).foregroundColor(TextMuted)
                Slider(value: $sat, in: 0.05...1).tint(RidgelineBlue)

                Text("Brightness").font(AscentFont.labelMedium).foregroundColor(TextMuted)
                Slider(value: $bright, in: 0.15...1).tint(RidgelineBlue)

                Button {
                    onConfirm(preview); dismiss()
                } label: {
                    Text("Use this color").fontWeight(.bold).foregroundColor(PureWhite)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(RidgelineBlue))
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Custom color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if UIColor(initial).getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            hue = Double(h); sat = max(Double(s), 0.05); bright = max(Double(b), 0.15)
        }
        #endif
    }
}
