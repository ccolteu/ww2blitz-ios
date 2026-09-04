import UIKit
import SpriteKit

class ParticleManager {
    static var instance: ParticleManager!

    private struct GrazeSpark {
        var x: Float = 0; var y: Float = 0
        var vx: Float = 0; var vy: Float = 0
        var life: Float = 0
        var isActive: Bool = false
    }

    private var pool    = (0..<POOL_SIZE).map { _ in ActiveExplosion() }
    private var sparks  = [GrazeSpark](repeating: GrazeSpark(), count: SPARK_POOL)
    private var sparkNodes: [SKShapeNode] = []

    private weak var scene: SKScene?
    private var explosionFrames: [SKTexture] = []
    private var drawW: CGFloat = 80
    private var drawH: CGFloat = 80

    static let POOL_SIZE    = 28
    static let FRAME_COUNT  = 8
    static let LAST_FRAME   = 7
    static let FRAME_SEC: Float = 0.05
    static let EXPLOSION_WIDTH_FRAC: Float = 0.18 * 1.5
    static let SPARK_POOL   = 48
    static let SPARK_LIFE: Float = 0.12
    static let SPARK_RADIUS: Float = 2.4

    func setup(scene: SKScene, screenWidth: CGFloat) {
        self.scene = scene
        loadExplosionFrames()
        onSizeChanged(screenWidth: screenWidth)
        let r = CGFloat(ParticleManager.SPARK_RADIUS)
        let sparkColor = UIColor(red: 1, green: 0xF2 / 255, blue: 0xA0 / 255, alpha: 1)
        for _ in 0..<ParticleManager.SPARK_POOL {
            let n = SKShapeNode(circleOfRadius: r)
            n.fillColor = sparkColor
            n.strokeColor = .clear
            n.zPosition = 55
            n.isHidden = true
            scene.addChild(n)
            sparkNodes.append(n)
        }
        ParticleManager.instance = self
    }

    func onSizeChanged(screenWidth: CGFloat) {
        // Sheet is 1536×1024 → 8 cells of 192×1024. Android keeps that aspect.
        let cellW: CGFloat = 192
        let cellH: CGFloat = 1024
        if let first = explosionFrames.first {
            let sz = first.size()
            if sz.width > 1 {
                drawW = screenWidth * CGFloat(ParticleManager.EXPLOSION_WIDTH_FRAC)
                drawH = drawW * (sz.height / sz.width)
                return
            }
        }
        drawW = screenWidth * CGFloat(ParticleManager.EXPLOSION_WIDTH_FRAC)
        drawH = drawW * (cellH / cellW)
    }

    private func loadExplosionFrames() {
        guard let image = StageBitmaps.loadImage(named: "Images/explosion_sheet", keyed: true),
              let cg = image.cgImage else {
            explosionFrames = []
            return
        }
        let cellW = max(cg.width / ParticleManager.FRAME_COUNT, 1)
        let cellH = max(cg.height, 1)
        explosionFrames = (0..<ParticleManager.FRAME_COUNT).compactMap { i in
            let crop = CGRect(x: i * cellW + 2, y: 0, width: max(cellW - 4, 1), height: cellH)
            guard let piece = cg.cropping(to: crop) else { return nil }
            let tex = SKTexture(image: UIImage(cgImage: piece, scale: image.scale, orientation: .up))
            tex.filteringMode = .linear
            return tex
        }
    }

    func triggerSpark(x: Float, y: Float, vx: Float, vy: Float) {
        for i in 0..<ParticleManager.SPARK_POOL {
            if !sparks[i].isActive {
                sparks[i] = GrazeSpark(x: x, y: y, vx: vx, vy: vy,
                                       life: ParticleManager.SPARK_LIFE, isActive: true)
                return
            }
        }
    }

    func spawnExplosion(x: Float, y: Float) { triggerExplosion(x: x, y: y, playSound: false) }

    func triggerExplosion(x: Float, y: Float, playSound: Bool = true) {
        if playSound { SoundManager.instance.playSFX(SoundManager.SFX_SMALL_EXPLOSION) }
        if let slot = pool.first(where: { !$0.isActive }) {
            slot.x = x; slot.y = y
            slot.currentFrameTime = 0; slot.currentFrameIndex = 0
            slot.isActive = true
            if let scene = scene, !explosionFrames.isEmpty {
                let node = SKSpriteNode(texture: explosionFrames[0])
                node.size = CGSize(width: drawW, height: drawH)
                node.position = CGPoint(x: CGFloat(x), y: scene.size.height - CGFloat(y))
                node.zPosition = 55
                node.name = "exp"
                let anim = SKAction.animate(with: explosionFrames,
                                            timePerFrame: Double(ParticleManager.FRAME_SEC))
                node.run(SKAction.sequence([anim, SKAction.removeFromParent()]))
                scene.addChild(node)
            }
            slot.isActive = false
        }
    }

    func update(dt: Float) {
        let h = Float(scene?.size.height ?? 0)
        for i in 0..<ParticleManager.SPARK_POOL {
            if sparks[i].isActive {
                sparks[i].x += sparks[i].vx * dt
                sparks[i].y += sparks[i].vy * dt
                sparks[i].life -= dt
                if sparks[i].life <= 0 { sparks[i].isActive = false }
            }
            let n = sparkNodes[i]
            if sparks[i].isActive {
                n.isHidden = false
                n.position = CGPoint(x: CGFloat(sparks[i].x), y: CGFloat(h - sparks[i].y))
            } else {
                n.isHidden = true
            }
        }
    }

    func activeSparks() -> [(x: Float, y: Float)] {
        sparks.filter { $0.isActive }.map { (x: $0.x, y: $0.y) }
    }
}
