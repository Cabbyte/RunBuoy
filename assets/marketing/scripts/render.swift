// Run from the repository root: swift assets/marketing/scripts/render.swift
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
func phone(_ path: String, x: CGFloat, y: CGFloat, width: CGFloat) {
    let h = width * 2868 / 1320
    box(rect(x-12,y-12,width+24,h+24),color(0x243145),radius:width*0.15,shadow:true)
    image(path,rect(x,y,width,h),radius:width*0.135)
}
func brand(_ locale: String, number: Int) {
    image("sources/brand-icon.png",rect(100,95,58,58),radius:15)
    text("RunBuoy",rect(178,98,330,66),size:42,weight:.semibold)
    text(String(format:"%02d / 06",number),rect(980,105,240,55),size:30,color:muted,align:.right)
}
func background(_ index: Int) {
    let end = index == 2 ? color(0xe9f7f3) : index == 6 ? color(0xebeaf9) : color(0xe3eeff)
    NSGradient(starting:color(0xf9fbff), ending:end)!.draw(in:rect(0,0,1320,2868),angle:90)
    // Quiet concentric ripples tie the system to the buoy, without decorative clutter.
    context.saveGState(); context.setStrokeColor(blue.withAlphaComponent(0.055).cgColor); context.setLineWidth(2)
    for n in 0..<3 { let d = CGFloat(1250 + n*270); context.strokeEllipse(in:rect(650-d/2,2000-d/2,d,d)) }
    context.restoreGState()
}
struct Slide: Decodable { let id: String; let title: String; let subtitle: String; let footnote: String }
struct LocaleCopy: Decodable { let slides: [Slide] }
let copy = try! JSONDecoder().decode([String:LocaleCopy].self,from:Data(contentsOf:base.appendingPathComponent("sources/copy.json")))
let locales = ["zh-Hans","en-US"]
// Crops use original 1320 x 2868 simulator pixel coordinates; see sources/captures.json.
let lockCrop = rect(60, 2136, 1200, 290)
for locale in locales {
    let shots = "sources/screenshots/\(locale)/"
    for (index, slide) in copy[locale]!.slides.enumerated() {
        render("promoted/app-store/\(locale)/\(String(format:"%02d",index+1))-\(slide.id).png",width:1320,height:2868) {
            background(index+1); brand(locale,number:index+1)
            text(slide.title,rect(100,245,1120,320),size:locale == "zh-Hans" ? 100 : 104,weight:.bold,spacing:5)
            text(slide.subtitle,rect(105,590,1110,145),size:40,color:muted,spacing:8)
            switch index {
            case 0:
                phone(shots+"lock-screen.png",x:292,y:850,width:736)
                box(rect(78,1988,1164,300),color(0x14151a),radius:64,shadow:true)
                image(shots+"lock-screen.png",rect(90,2000,1140,275.5),crop:lockCrop,radius:55)
                text(locale == "zh-Hans" ? "实时活动 · 灵动岛" : "Live Activities · Dynamic Island",rect(100,2500,1120,85),size:38,weight:.medium,color:blue,align:.center)
            case 1:
                box(rect(78,810,1164,1820),color(0xf5f5fc),radius:50,shadow:true)
                image(shots+"history.png",rect(90,830,1140,1780),crop:rect(0,160,1320,2061),radius:40)
            case 2:
                phone(shots+"active-runs.png",x:235,y:800,width:850)
            case 3:
                box(rect(78,790,1164,1895),color(0xf5f5fc),radius:50,shadow:true)
                image(shots+"run-detail.png",rect(90,805,1140,1865),crop:rect(0,140,1320,2160),radius:40)
            case 4:
                phone(shots+"pairing.png",x:235,y:790,width:850)
            default:
                box(rect(78,835,1164,580),color(0xf5f5fc),radius:50,shadow:true)
                image(shots+"data.png",rect(100,860,1120,510),crop:rect(0,130,1320,601),radius:36)
                let labels = locale == "zh-Hans" ? ["电脑执行任务", "Server 转发状态", "iPhone 只读展示"] : ["Your computer runs it", "Server relays status", "iPhone keeps you in view"]
                for (n,label) in labels.enumerated() {
                    let yy = CGFloat(1560+n*220)
                    box(rect(150,yy,1020,155),NSColor.white.withAlphaComponent(0.8),radius:28)
                    text("0\(n+1)",rect(195,yy+41,85,68),size:40,weight:.medium,color:blue)
                    text(label,rect(310,yy+40,810,80),size:43,weight:.semibold)
                    if n < 2 { text("↓",rect(610,yy+160,100,65),size:36,color:muted,align:.center) }
                }
                text(locale == "zh-Hans" ? "不在手机上启动、停止或重试任务。" : "No remote start, stop, or retry.",rect(150,2340,1020,155),size:38,color:muted,align:.center)
            }
            text(slide.footnote,rect(100,2730,1120,100),size:28,color:muted,align:.center,spacing:5)
        }
    }
    render("promoted/web/\(locale)/active-runs.jpg",width:660,height:1434) { image(shots+"active-runs.png",rect(0,0,660,1434)) }
    render("promoted/web/\(locale)/run-detail.jpg",width:660,height:1120) { image(shots+"run-detail.png",rect(0,0,660,1120),crop:rect(0,160,1320,2240)) }
    render("promoted/web/\(locale)/live-activity.png",width:1200,height:290) { image(shots+"lock-screen.png",rect(0,0,1200,290),crop:lockCrop) }
}
render("promoted/web/buoy-calm-water.jpg",width:1536,height:1024) { image("sources/generated/buoy-calm-water-v1.png",rect(0,0,1536,1024)) }
render("promoted/web/og.png",width:1200,height:630) {
    image("sources/generated/buoy-calm-water-v1.png",rect(0,-85,1200,800))
    image("sources/brand-icon.png",rect(70,80,68,68),radius:18)
    text("RunBuoy",rect(160,91,420,70),size:42,weight:.semibold)
    text("离开电脑，\n进度就在手边。",rect(70,210,760,230),size:65,weight:.bold,spacing:12)
    text("Mac / Linux → iPhone",rect(73,495,680,62),size:27,color:muted)
}
render("promoted/web/en-US/og.png",width:1200,height:630) {
    image("sources/generated/buoy-calm-water-v1.png",rect(0,-85,1200,800))
    image("sources/brand-icon.png",rect(70,80,68,68),radius:18)
    text("RunBuoy",rect(160,91,420,70),size:42,weight:.semibold)
    text("Step away.\nStay in the know.",rect(70,210,760,230),size:65,weight:.bold,spacing:12)
    text("Mac / Linux → iPhone",rect(73,495,680,62),size:27,color:muted)
}
for locale in locales {
    render("verification/app-store-\(locale)-overview.jpg",width:1980,height:1564) {
        box(rect(0,0,1980,1564),color(0xeaf0f9))
        for (i,slide) in copy[locale]!.slides.enumerated() {
            let x = CGFloat(i%3)*650+25, y = CGFloat(i/3)*770+18
            image("promoted/app-store/\(locale)/\(String(format:"%02d",i+1))-\(slide.id).png",rect(x,y,340,739),radius:14)
            text(slide.title.replacingOccurrences(of:"\n",with:" "),rect(x+365,y+40,225,230),size:25,weight:.semibold,spacing:6)
            text(slide.subtitle,rect(x+365,y+295,225,370),size:19,color:muted,spacing:6)
        }
    }
}
let manifest = try! JSONSerialization.data(withJSONObject:["generator":"scripts/render.swift","exports":outputRecords], options:[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes])
try! manifest.write(to:base.appendingPathComponent("promoted/exports.json"))
let webDest = root.appendingPathComponent("website/docs/public/marketing")
try! fm.createDirectory(at:webDest,withIntermediateDirectories:true)
for locale in locales {
    let target = webDest.appendingPathComponent(locale)
    try! fm.createDirectory(at:target,withIntermediateDirectories:true)
    let names = ["active-runs.jpg","run-detail.jpg","live-activity.png"] + (locale == "en-US" ? ["og.png"] : [])
    for name in names {
        let dest = target.appendingPathComponent(name)
        if fm.fileExists(atPath:dest.path) { try! fm.removeItem(at:dest) }
        try! fm.copyItem(at:base.appendingPathComponent("promoted/web/\(locale)/\(name)"),to:dest)
    }
}
for name in ["buoy-calm-water.jpg"] {
    let dest = webDest.appendingPathComponent(name)
    if fm.fileExists(atPath:dest.path) { try! fm.removeItem(at:dest) }
    try! fm.copyItem(at:base.appendingPathComponent("promoted/web/\(name)"),to:dest)
}
let og = root.appendingPathComponent("website/docs/public/og.png")
if fm.fileExists(atPath:og.path) { try! fm.removeItem(at:og) }
try! fm.copyItem(at:base.appendingPathComponent("promoted/web/og.png"),to:og)
