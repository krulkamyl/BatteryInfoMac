import AppKit
import CoreGraphics

// Converts a raw square image into a macOS HIG squircle icon (1024x1024 transparent PNG)
// and packs a complete multi-resolution Apple .icns file directly.

guard CommandLine.arguments.count >= 4 else {
    fputs("Usage: make_icon <input_image> <output_png_1024> <output_icns>\n", stderr)
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPngPath = CommandLine.arguments[2]
let outputIcnsPath = CommandLine.arguments[3]

guard let srcImage = NSImage(contentsOfFile: inputPath),
      let srcCG = srcImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Error: failed to load input image at \(inputPath)\n", stderr)
    exit(1)
}

func renderSquircleIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // macOS HIG icon grid: ~80.5% body size centered with subtle drop shadow
    let inset = s * 0.0975
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = rect.width * 0.2237 // Apple continuous rounded rect ratio
    let squirclePath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Subtle macOS Dock drop shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -s * 0.014),
        blur: s * 0.032,
        color: CGColor(gray: 0, alpha: 0.34)
    )
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to squircle and draw source artwork
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    ctx.draw(srcCG, in: rect)

    // Subtle inner top-edge glass rim highlight
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(CGColor(gray: 1.0, alpha: 0.24))
    ctx.setLineWidth(max(1.0, s * 0.004))
    ctx.strokePath()
    ctx.restoreGState()

    guard let outCG = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: outCG)
    return rep.representation(using: .png, properties: [:])
}

let fm = FileManager.default
try? fm.createDirectory(atPath: (outputPngPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
try? fm.createDirectory(atPath: (outputIcnsPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)

if let png1024 = renderSquircleIcon(size: 1024) {
    try png1024.write(to: URL(fileURLWithPath: outputPngPath))
}

// Standard Apple ICNS PNG chunk types (16px through 1024px including @2x Retina)
let icnsChunks: [(String, Int)] = [
    ("icp4", 16),   // 16x16
    ("icp5", 32),   // 32x32
    ("ic11", 32),   // 16x16@2x
    ("icp6", 64),   // 64x64
    ("ic12", 64),   // 32x32@2x
    ("ic07", 128),  // 128x128
    ("ic08", 256),  // 256x256
    ("ic13", 256),  // 128x128@2x
    ("ic09", 512),  // 512x512
    ("ic14", 512),  // 256x256@2x
    ("ic10", 1024)  // 512x512@2x
]

var renderedBySize: [Int: Data] = [:]
var body = Data()

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
    var be = value.bigEndian
    withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
}

for (fourCC, px) in icnsChunks {
    let pngData: Data
    if let cached = renderedBySize[px] {
        pngData = cached
    } else {
        guard let d = renderSquircleIcon(size: px) else {
            fputs("Failed rendering \(px)px\n", stderr)
            exit(1)
        }
        renderedBySize[px] = d
        pngData = d
    }

    body.append(contentsOf: fourCC.utf8)
    appendUInt32BE(UInt32(8 + pngData.count), to: &body)
    body.append(pngData)
}

var icnsData = Data()
icnsData.append(contentsOf: "icns".utf8)
appendUInt32BE(UInt32(8 + body.count), to: &icnsData)
icnsData.append(body)

try icnsData.write(to: URL(fileURLWithPath: outputIcnsPath))
print("Generated squircle PNG and multi-resolution AppIcon.icns successfully (\(icnsData.count) bytes).")
