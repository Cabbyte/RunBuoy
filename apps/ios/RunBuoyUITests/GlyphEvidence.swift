import UIKit
import XCTest

/// Measures the first rendered glyph, independently of line count and text-frame height.
struct GlyphEvidence {
    let size: CGSize
    let pixelBounds: CGRect
    let scale: CGFloat

    static func rendered(_ image: UIImage, scale: CGFloat) throws -> GlyphEvidence {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        try rgba.withUnsafeMutableBytes { data in
            let context = try XCTUnwrap(CGContext(
                data: data.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            ))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        var histogram = [Int](repeating: 0, count: 256)
        var luminance = [UInt8](repeating: 0, count: width * height)
        for i in luminance.indices {
            let base = i * 4
            let value = (54 * Int(rgba[base]) + 183 * Int(rgba[base + 1])
                + 19 * Int(rgba[base + 2])) / 256
            luminance[i] = UInt8(value)
            histogram[value] += 1
        }
        var cumulative = 0
        let background = histogram.indices.first { value in
            cumulative += histogram[value]
            return cumulative >= luminance.count / 2
        } ?? 255
        var foreground = luminance.map { abs(Int($0) - background) > 64 }
        var occupiedRows = [Bool](repeating: false, count: height)
        for y in 0..<height {
            occupiedRows[y] = (0..<width).contains { foreground[y * width + $0] }
        }
        let firstRow = try XCTUnwrap(occupiedRows.firstIndex(of: true), "No glyph pixels")
        var endRow = firstRow
        while endRow < height && occupiedRows[endRow] { endRow += 1 }

        var components: [CGRect] = []
        for y in firstRow..<endRow {
            for x in 0..<width where foreground[y * width + x] {
                var queue = [y * width + x]
                foreground[y * width + x] = false
                var cursor = 0
                var minX = x, maxX = x, minY = y, maxY = y
                while cursor < queue.count {
                    let index = queue[cursor]
                    cursor += 1
                    let currentX = index % width
                    let currentY = index / width
                    minX = min(minX, currentX); maxX = max(maxX, currentX)
                    minY = min(minY, currentY); maxY = max(maxY, currentY)
                    for dy in -1...1 {
                        for dx in -1...1 {
                            let nextX = currentX + dx, nextY = currentY + dy
                            guard nextX >= 0, nextX < width,
                                  nextY >= firstRow, nextY < endRow else { continue }
                            let next = nextY * width + nextX
                            if foreground[next] {
                                foreground[next] = false
                                queue.append(next)
                            }
                        }
                    }
                }
                if maxY - minY + 1 >= max(2, (endRow - firstRow) / 3) {
                    components.append(CGRect(x: minX, y: minY,
                                             width: maxX - minX + 1, height: maxY - minY + 1))
                }
            }
        }
        let bounds = try XCTUnwrap(components.min { lhs, rhs in
            lhs.minX == rhs.minX ? lhs.height > rhs.height : lhs.minX < rhs.minX
        }, "No connected glyph in the first line")
        return GlyphEvidence(
            size: CGSize(width: bounds.width / scale, height: bounds.height / scale),
            pixelBounds: bounds, scale: scale
        )
    }

    static func reference(character: String, style: UIFont.TextStyle,
                          category: UIContentSizeCategory, scale: CGFloat) throws -> GlyphEvidence {
        let font = UIFont.preferredFont(
            forTextStyle: style,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: category)
        )
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let textSize = (character as NSString).size(withAttributes: attributes)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let canvas = CGSize(width: ceil(textSize.width) + 16, height: ceil(font.lineHeight) + 16)
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))
            (character as NSString).draw(at: CGPoint(x: 8, y: 8), withAttributes: attributes)
        }
        return try rendered(image, scale: scale)
    }
}
