// 生成 Oolong app 图标：暖米白 squircle + 陶土橙茶杯 (cup.and.saucer.fill)
// 用法: swift scripts/make-icon.swift <输出.png>
import AppKit

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let size: CGFloat = 1024

let cream = NSColor(red: 0.949, green: 0.941, blue: 0.914, alpha: 1)
let clay = NSColor(red: 0.851, green: 0.467, blue: 0.341, alpha: 1)
let border = NSColor(red: 0.851, green: 0.467, blue: 0.341, alpha: 0.25)

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// macOS 图标网格：1024 画布，内容 squircle 居中留边
let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = rect.width * 0.2237
let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
cream.setFill()
squircle.fill()
border.setStroke()
squircle.lineWidth = 8
squircle.stroke()

// 茶杯符号，陶土橙；杯口镂空处先垫一层琥珀色茶汤(乌龙茶汤色)
let amber = NSColor(red: 0.78, green: 0.50, blue: 0.18, alpha: 1)
let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .medium)
    .applying(.init(paletteColors: [clay]))
if let sym = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let s = sym.size
    let scale = min(rect.width * 0.62 / s.width, rect.height * 0.62 / s.height)
    let w = s.width * scale, h = s.height * scale
    let drawRect = NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h)

    // 茶汤：盖住杯口镂空区域，画在 symbol 之下
    let tea = NSBezierPath(ovalIn: NSRect(
        x: drawRect.midX - w * 0.26,
        y: drawRect.maxY - h * 0.37,
        width: w * 0.44,
        height: h * 0.21
    ))
    amber.setFill()
    tea.fill()

    sym.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
} else {
    fputs("找不到 SF Symbol cup.and.saucer.fill\n", stderr)
    exit(1)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
else {
    fputs("PNG 编码失败\n", stderr)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: out))
print("✓ 生成 \(out) (\(png.count / 1024) KB)")
