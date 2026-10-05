// Run from repository root: swift assets/marketing/scripts/render-website-zh.swift
// Native AppKit typography + real simulator captures. No UI is synthesized.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("assets/marketing")
let fm = FileManager.default
let ink = NSColor(srgbRed: 0.075, green: 0.13, blue: 0.22, alpha: 1)
let muted = NSColor(srgbRed: 0.32, green: 0.39, blue: 0.48, alpha: 1)
let blue = NSColor(srgbRed: 0.08, green: 0.43, blue: 0.79, alpha: 1)
let pale = NSColor(srgbRed: 0.955, green: 0.972, blue: 0.995, alpha: 1)
var context: CGContext!
var outputRecords: [[String: Any]] = []

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255, blue: CGFloat(hex & 255)/255, alpha: 1)
}
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x:x, y:y, width:w, height:h) }
func box(_ r: CGRect, _ c: NSColor, radius: CGFloat = 0, shadow: Bool = false) {
    context.saveGState()
    if shadow { context.setShadow(offset: CGSize(width: 0, height: 18), blur: 36, color: color(0x173660).withAlphaComponent(0.16).cgColor) }
    c.setFill()
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
    context.restoreGState()
}
func line(_ from: CGPoint, _ to: CGPoint, _ c: NSColor, width: CGFloat = 2) {
    context.saveGState(); context.setStrokeColor(c.cgColor); context.setLineWidth(width)
    context.move(to: from); context.addLine(to: to); context.strokePath(); context.restoreGState()
}
@discardableResult
func text(_ str: String, _ r: CGRect, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = ink, align: NSTextAlignment = .left, spacing: CGFloat = 8) -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineSpacing = spacing
    paragraph.lineBreakMode = .byWordWrapping
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font:font, .foregroundColor:color, .paragraphStyle:paragraph, .kern: -size * 0.018]
    let value = NSAttributedString(string:str, attributes:attrs)
    let bounds = value.boundingRect(with: CGSize(width:r.width, height:10000), options:[.usesLineFragmentOrigin, .usesFontLeading])
    precondition(bounds.height <= r.height + 5, "Text overflows: \(str) [\(bounds.height) > \(r.height)]")
    value.draw(with:r, options:[.usesLineFragmentOrigin, .usesFontLeading])
    return bounds.height
}
func image(_ path: String, _ r: CGRect, crop: CGRect? = nil, radius: CGFloat = 0) {
    let url = base.appendingPathComponent(path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let full = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("Missing image \(url.path)") }
    let img = crop.map { full.cropping(to:$0)! } ?? full
    let ns = NSImage(cgImage:img, size:NSSize(width:img.width,height:img.height))
    context.saveGState()
    NSBezierPath(roundedRect:r, xRadius:radius, yRadius:radius).addClip()
    ns.draw(in:r, from:.zero, operation:.sourceOver, fraction:1, respectFlipped:true, hints:[.interpolation:NSImageInterpolation.high])
    context.restoreGState()
}
func render(_ relative: String, width: Int, height: Int, _ drawing: () -> Void) {
    let url = base.appendingPathComponent(relative)
    try! fm.createDirectory(at:url.deletingLastPathComponent(), withIntermediateDirectories:true)
    let previous = context
    context = CGContext(data:nil, width:width, height:height, bitsPerComponent:8, bytesPerRow:width*4, space:CGColorSpace(name:CGColorSpace.sRGB)!, bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.translateBy(x:0,y:CGFloat(height)); context.scaleBy(x:1,y:-1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext:context, flipped:true)
    context.interpolationQuality = .high
    box(rect(0,0,CGFloat(width),CGFloat(height)), .white)
    drawing()
    NSGraphicsContext.restoreGraphicsState()
    let jpg = url.pathExtension == "jpg"
    let dest = CGImageDestinationCreateWithURL(url as CFURL, (jpg ? UTType.jpeg.identifier : UTType.png.identifier) as CFString, 1, nil)!
    let props: [CFString:Any] = jpg ? [kCGImageDestinationLossyCompressionQuality:0.91] : [:]
    CGImageDestinationAddImage(dest, context.makeImage()!, props as CFDictionary)
    precondition(CGImageDestinationFinalize(dest), "Failed to write \(url.path)")
    context = previous
    outputRecords.append(["path":relative,"width":width,"height":height,"alpha":false])
    print(relative)
}

render("promoted/web/zh-Hans/og.png", width:1200, height:630) {
    image("sources/generated/buoy-calm-water-v1.png", rect(0,-85,1200,800))
    image("sources/brand-icon.png", rect(70,70,68,68), radius:18)
    text("RunBuoy", rect(160,81,420,70), size:42, weight:.semibold)
    text("扫一眼，\n掌握任务的进展。", rect(70,205,1040,230), size:65, weight:.bold, spacing:12)
    text("阶段、结果随手看，重要消息随身收。", rect(73,465,1050,65), size:27, color:muted)
    text("Mac / Linux → iPhone", rect(73,540,680,55), size:24, color:muted)
}
let destination = root.appendingPathComponent("website/docs/public/marketing/zh-Hans/og.png")
if fm.fileExists(atPath:destination.path) { try! fm.removeItem(at:destination) }
try! fm.copyItem(at:base.appendingPathComponent("promoted/web/zh-Hans/og.png"), to:destination)
