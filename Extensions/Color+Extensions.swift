import SwiftUI

extension Color {
    /// 16進数文字列からColorを初期化するイニシャライザ
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // '#'が先頭にある場合は除去
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        // RGBまたはRGBAの形式（6または8文字）か確認
        var rgbValue: UInt64 = 0
        let length = hex.count

        guard Scanner(string: hex).scanHexInt64(&rgbValue) else {
            return nil
        }

        switch length {
        case 6: // RGB (24ビット)
            let red = Double((rgbValue & 0xFF0000) >> 16) / 255
            let green = Double((rgbValue & 0x00FF00) >> 8) / 255
            let blue = Double(rgbValue & 0x0000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        case 8: // RGBA (32ビット)
            let red = Double((rgbValue & 0xFF000000) >> 24) / 255
            let green = Double((rgbValue & 0x00FF0000) >> 16) / 255
            let blue = Double((rgbValue & 0x0000FF00) >> 8) / 255
            let alpha = Double(rgbValue & 0x000000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        default:
            // 不正な文字数の場合
            return nil
        }
    }

    /// Colorから16進数文字列を取得するメソッド
    func toHex(includeAlpha: Bool = false) -> String? {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return nil
        }
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        let alpha = rgbColor.alphaComponent
        #else
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        #endif

        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)

        if includeAlpha || a < 255 {
            // アルファ値を含める場合
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            // アルファ値を含めない場合
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}
