import UIKit
import SpriteKit

enum SpriteKey {
    case none
    case green   // ship / enemy / item sheets
    case lime    // HUD hit pips
}

/// Android layout was authored in ~1080×1920 pixels. Scene size is points.
enum LayoutPx {
    static func scale(width: CGFloat, height: CGFloat) -> Float {
        max(0.25, Float(min(width / 1080, height / 1920)))
    }
}

/// Android blitOutlined: 3px black ring + 2px drop shadow (y-down).
enum ArcadeOutline {
    static let outline: CGFloat = 3
    static let shadow: CGFloat = 2

    static func attach(to node: SKSpriteNode) {
        guard node.childNode(withName: "arcadeShadow") == nil else {
            sync(node)
            return
        }
        let shadow = SKSpriteNode(texture: node.texture)
        shadow.name = "arcadeShadow"
        shadow.zPosition = -2
        shadow.color = UIColor(white: 0, alpha: 1)
        shadow.colorBlendFactor = 1
        shadow.alpha = 0xCC / 255
        node.addChild(shadow)
        let o = ArcadeOutline.outline
        for oy in stride(from: -o, through: o, by: o) {
            for ox in stride(from: -o, through: o, by: o) {
                if ox == 0 && oy == 0 { continue }
                let ring = SKSpriteNode(texture: node.texture)
                ring.name = "arcadeOutline.\(Int(ox)).\(Int(oy))"
                ring.zPosition = -1
                ring.color = .black
                ring.colorBlendFactor = 1
                node.addChild(ring)
            }
        }
        sync(node)
    }

    static func sync(_ node: SKSpriteNode) {
        let s = ArcadeOutline.shadow
        for child in node.children {
            guard let sprite = child as? SKSpriteNode, let name = child.name else { continue }
            sprite.texture = node.texture
            sprite.size = node.size
            if name == "arcadeShadow" {
                sprite.position = CGPoint(x: s, y: -s)
            } else if name.hasPrefix("arcadeOutline.") {
                let parts = name.split(separator: ".")
                if parts.count == 3, let ox = Double(parts[1]), let oy = Double(parts[2]) {
                    sprite.position = CGPoint(x: CGFloat(ox), y: -CGFloat(oy))
                }
            }
        }
    }
}

/// Load PNG art from copied folder-reference directories (`Images/`, `Stages/…`).
enum GameArt {
    private static var cache: [String: SKTexture] = [:]

    static func texture(_ path: String, key: SpriteKey = .green) -> SKTexture {
        let cacheKey = "\(path)|\(key)"
        if let cached = cache[cacheKey] { return cached }
        let keyed = key != .none
        let lime = key == .lime
        if let image = StageBitmaps.loadImage(named: path, keyed: keyed, lime: lime) {
            let tex = SKTexture(image: image)
            tex.filteringMode = .nearest
            cache[cacheKey] = tex
            return tex
        }
        let stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let tex = SKTexture(imageNamed: stem)
        cache[cacheKey] = tex
        return tex
    }
}

/// Load stage PNGs from the bundle and apply green-key chroma removal.
struct StageBitmaps {
    static func loadTexture(named path: String, keyed: Bool = false, widthLock: CGFloat = 0) -> SKTexture? {
        guard let image = loadImage(named: path, keyed: keyed, widthLock: widthLock) else { return nil }
        let tex = SKTexture(image: image)
        tex.filteringMode = .linear
        return tex
    }

    /// 0 = top of the bitmap, 1 = bottom. 0.5 if the sheet is empty.
    static func opaqueMidYFraction(_ image: UIImage) -> Float {
        guard let cg = image.cgImage else { return 0.5 }
        let w = cg.width
        let h = cg.height
        guard w > 0, h > 0 else { return 0.5 }
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let data = ctx.data else { return 0.5 }
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        let pixels = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var minY = h
        var maxY = -1
        var i = 3
        let count = w * h
        for p in 0..<count {
            if pixels[i] > 16 {
                let y = p / w
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
            i += 4
        }
        if maxY < minY { return 0.5 }
        return Float(minY + maxY) * 0.5 / Float(max(h - 1, 1))
    }

    static func loadImage(named path: String, keyed: Bool = false, lime: Bool = false, widthLock: CGFloat = 0) -> UIImage? {
        let ns = path as NSString
        let file = ns.lastPathComponent
        let dir = ns.deletingLastPathComponent
        let base = (file as NSString).deletingPathExtension
        let ext  = (file as NSString).pathExtension.isEmpty ? "png" : (file as NSString).pathExtension
        let url: URL?
        if dir.isEmpty {
            url = Bundle.main.url(forResource: base, withExtension: ext)
        } else {
            url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: dir)
        }
        guard let url, var image = UIImage(contentsOfFile: url.path) else { return nil }
        if lime { image = keyLime(image) }
        else if keyed { image = keyGreen(image) }
        if widthLock > 0 && image.size.width != widthLock {
            let scale = widthLock / image.size.width
            let newH = ceil(image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: widthLock, height: newH))
            image = renderer.image { _ in image.draw(in: CGRect(x: 0, y: 0, width: widthLock, height: newH)) }
        }
        return image
    }

    /// Matches BossController.keyGreen — punches chroma and kills leftover green fringe.
    static func keyGreen(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let w = cg.width; let h = cg.height
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w*4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return image }
        let pixels = data.bindMemory(to: UInt8.self, capacity: w*h*4)
        for y in 0..<h {
            for x in 0..<w {
                let i = (y*w + x) * 4
                let r = Int(pixels[i]); let g = Int(pixels[i+1]); let b = Int(pixels[i+2])
                let maxRb = max(r, b)
                let excess = g - maxRb
                let chroma =
                    (g > 160 && g > r + 40 && g > b + 40) ||
                    (excess > 24 && g > 48 && g > r + 16 && g > b + 16) ||
                    (r + b < 90 && g > 22 && g > r + 10 && g > b + 10)
                if chroma {
                    pixels[i] = 0; pixels[i+1] = 0; pixels[i+2] = 0; pixels[i+3] = 0
                } else if excess > 6 {
                    let ng = min(255, maxRb + 3)
                    pixels[i+1] = UInt8(ng)
                }
            }
        }
        guard let out = ctx.makeImage() else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }

    static func keyLime(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let w = cg.width; let h = cg.height
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w*4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return image }
        let pixels = data.bindMemory(to: UInt8.self, capacity: w*h*4)
        for y in 0..<h {
            for x in 0..<w {
                let i = (y*w + x) * 4
                let r = Int(pixels[i]); let g = Int(pixels[i+1]); let b = Int(pixels[i+2])
                if g > 200 && r < 50 && b < 50 {
                    pixels[i] = 0; pixels[i+1] = 0; pixels[i+2] = 0; pixels[i+3] = 0
                }
            }
        }
        guard let out = ctx.makeImage() else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
}

class StageTheater {
    var def: StageDef = StageCatalog.get(1)
    private(set) var floorTex: SKTexture?
    private(set) var midTex: SKTexture?
    private(set) var highTex: SKTexture?
    private(set) var canopyTex: SKTexture?
    private(set) var floorAltTex: SKTexture?
    private(set) var briefingTex: SKTexture?
    private(set) var skinTankTex: SKTexture?
    private(set) var skinDestroyerTex: SKTexture?
    private(set) var skinWagonTex: SKTexture?
    private(set) var skinHelicopterTex: SKTexture?
    var activeFloorTex: SKTexture?
    var floorSwapped = false
    private var loadedId = -1

    func load(next: StageDef, width: CGFloat) {
        if loadedId == next.id && floorTex != nil { def = next; return }
        def = next; loadedId = next.id
        midTex = nil; highTex = nil; canopyTex = nil; floorAltTex = nil
        skinTankTex = nil; skinDestroyerTex = nil; skinWagonTex = nil; skinHelicopterTex = nil
        let lock = next.theaterKind == .ascent ? CGFloat(0) : width
        floorTex     = StageBitmaps.loadTexture(named: next.floorPath(), keyed: false, widthLock: lock)
        let keyed    = next.keyedOverlayLayers
        if let p = next.midPath()      { midTex      = StageBitmaps.loadTexture(named: p, keyed: keyed, widthLock: width) }
        if let p = next.highPath()     { highTex     = StageBitmaps.loadTexture(named: p, keyed: keyed, widthLock: width) }
        if let p = next.canopyPath()   { canopyTex   = StageBitmaps.loadTexture(named: p, keyed: true) }
        if let p = next.floorAltPath() { floorAltTex = StageBitmaps.loadTexture(named: p, keyed: false) }
        briefingTex  = StageBitmaps.loadTexture(named: next.briefingPath(), keyed: false)
        if let p = next.skinTankPath()      { skinTankTex      = StageBitmaps.loadTexture(named: p, keyed: true) }
        if let p = next.skinDestroyerPath() { skinDestroyerTex = StageBitmaps.loadTexture(named: p, keyed: true) }
        if let p = next.skinWagonPath()     { skinWagonTex     = StageBitmaps.loadTexture(named: p, keyed: true) }
        if let p = next.skinHelicopterPath() { skinHelicopterTex = StageBitmaps.loadTexture(named: p, keyed: true) }
        floorSwapped = false; activeFloorTex = floorTex
    }

    func swapToFloorAlt() { if let alt = floorAltTex { floorSwapped = true; activeFloorTex = alt } }
    var hasOverlayClouds: Bool { def.hasOverlayClouds }
    var isFacilityTheater: Bool { def.theaterKind == .facility }
    var isAscentTheater: Bool { def.theaterKind == .ascent }
}
