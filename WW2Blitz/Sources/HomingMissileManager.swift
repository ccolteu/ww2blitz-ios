import SpriteKit

class HomingMissileManager {
    class Missile {
        var x: Float = 0; var y: Float = 0
        var vx: Float = 0; var vy: Float = 0
        var isActive: Bool = false
    }

    static let POOL_SIZE = 8
    static let MISSILE_SPEED: Float = 650
    static let TURN_RATE: Float = 8.5
    static let DRAW_W: Float = 48
    static let DRAW_H: Float = 96

    private(set) var pool = (0..<POOL_SIZE).map { _ in Missile() }
    private var screenW: Float = 0
    private var screenH: Float = 0

    // SpriteKit
    private weak var scene: SKScene?
    private var missileNodes: [SKSpriteNode] = []
    private var missileTexture: SKTexture!

    func setup(scene: SKScene) {
        self.scene = scene
        onSizeChanged(width: scene.size.width, height: scene.size.height)
        missileTexture = GameArt.texture("Images/player_missile")
        let s = LayoutPx.scale(width: scene.size.width, height: scene.size.height)
        for _ in 0..<HomingMissileManager.POOL_SIZE {
            let n = SKSpriteNode(texture: missileTexture)
            n.size = CGSize(width: CGFloat(HomingMissileManager.DRAW_W * s),
                            height: CGFloat(HomingMissileManager.DRAW_H * s))
            n.zPosition = 39; n.isHidden = true
            scene.addChild(n); missileNodes.append(n)
            ArcadeOutline.attach(to: n)
        }
    }

    func onSizeChanged(width: CGFloat, height: CGFloat) {
        screenW = Float(width); screenH = Float(height)
        let s = LayoutPx.scale(width: width, height: height)
        for n in missileNodes {
            n.size = CGSize(width: CGFloat(HomingMissileManager.DRAW_W * s),
                            height: CGFloat(HomingMissileManager.DRAW_H * s))
            ArcadeOutline.sync(n)
        }
    }

    func fireMissile(startX: Float, startY: Float, initVx: Float, initVy: Float) {
        if let m = pool.first(where: { !$0.isActive }) {
            m.x = startX; m.y = startY; m.vx = initVx; m.vy = initVy; m.isActive = true
        }
    }

    func deactivateAll() {
        pool.forEach { $0.isActive = false }
        missileNodes.forEach { $0.isHidden = true }
    }
    func getPoolSize() -> Int { HomingMissileManager.POOL_SIZE }

    func update(dt: Float, enemyPool: [Enemy], poolSize: Int, boss: BossController) {
        let sceneH = scene.map { Float($0.size.height) } ?? screenH
        for (i, m) in pool.enumerated() {
            guard m.isActive else { missileNodes[i].isHidden = true; continue }
            var targetX: Float = 0; var targetY: Float = -100; var found = false
            var closestDistSq = Float.greatestFiniteMagnitude
            for ei in 0..<poolSize {
                let e = enemyPool[ei]
                if e.isActive && e.y > 0 {
                    let dx = e.x - m.x; let dy = e.y - m.y
                    let d = dx*dx + dy*dy
                    if d < closestDistSq { closestDistSq = d; targetX = e.x; targetY = e.y; found = true }
                }
            }
            if boss.isActive() {
                let parts = boss.getComponents()
                for pi in 0..<boss.getComponentCount() {
                    let p = parts[pi]
                    if !p.isDestroyed && p.halfW > 0 && p.y > 0 {
                        let dx = p.x - m.x; let dy = p.y - m.y
                        let d = dx*dx + dy*dy
                        if d < closestDistSq { closestDistSq = d; targetX = p.x; targetY = p.y; found = true }
                    }
                }
            }
            if found {
                let dx = targetX - m.x; let dy = targetY - m.y
                let len = sqrtf(dx*dx + dy*dy)
                if len > 0.1 {
                    let tvx = (dx/len) * HomingMissileManager.MISSILE_SPEED
                    let tvy = (dy/len) * HomingMissileManager.MISSILE_SPEED
                    m.vx += (tvx - m.vx) * HomingMissileManager.TURN_RATE * dt
                    m.vy += (tvy - m.vy) * HomingMissileManager.TURN_RATE * dt
                }
            } else {
                m.vy += (-HomingMissileManager.MISSILE_SPEED - m.vy) * HomingMissileManager.TURN_RATE * dt
            }
            m.x += m.vx * dt; m.y += m.vy * dt
            if m.y < -30 || m.x < -30 || m.x > screenW + 30 || m.y > screenH + 30 {
                m.isActive = false
            }
            // Render
            let n = missileNodes[i]
            if m.isActive {
                n.isHidden = false
                n.zRotation = CGFloat(-atan2f(m.vy, m.vx) - Float.pi / 2)
                n.position = CGPoint(x: CGFloat(m.x), y: CGFloat(sceneH - m.y))
                ArcadeOutline.sync(n)
            } else { n.isHidden = true }
        }
    }
}
