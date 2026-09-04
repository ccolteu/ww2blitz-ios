import SpriteKit

// MARK: - Item types (match Android PowerUpItem)
struct ItemType {
    static let WEAPON_UP        = PowerUpSlot.ITEM_TYPE_POWERUP
    static let MEDAL            = PowerUpSlot.ITEM_TYPE_MEDAL
    static let BOMB_STOCK       = PowerUpSlot.ITEM_TYPE_BOMB
    static let SHIELD_RECOVERY  = PowerUpSlot.ITEM_TYPE_SHIELD
}

class PowerUpSlot {
    var x: Float = 0; var y: Float = 0
    var vx: Float = 0; var vy: Float = 0
    var homeX: Float = 0; var swayT: Float = 0
    var swayDrop: Bool = false
    var pickupPoints: Int = 0
    var isSecretMedal: Bool = false
    var isActive: Bool = false
    var itemType: Int = PowerUpSlot.ITEM_TYPE_POWERUP
    var medalFrameTime: Float = 0
    var medalFrameIndex: Int = 0

    static let ITEM_TYPE_POWERUP = 0
    static let ITEM_TYPE_MEDAL   = 1
    static let ITEM_TYPE_BOMB    = 2
    static let ITEM_TYPE_SHIELD  = 3
}

class PowerUpItem {
    static let POOL_SIZE = 48
    private(set) var pool = (0..<POOL_SIZE).map { _ in PowerUpSlot() }

    static let SWAY_VY: Float    = 72
    static let SWAY_RATE: Float  = 3.2
    static let SWAY_AMP: Float   = 28
    static let MAGNET_RADIUS: Float      = 96
    static let MAGNET_EDGE_RADIUS: Float = 188
    static let MAGNET_SPEED: Float       = 420
    static let MEDAL_FRAME_COUNT = 8
    static let MEDAL_FRAME_SEC: Float = 1.0 / 15.0
    static let EDGE_STRIP_FRAC: Float = 0.10
    static let POWERUP_HALF: Float = 78
    static let MEDAL_HALF: Float   = 36

    private weak var scene: SKScene?
    private var nodes: [SKSpriteNode] = []
    private var powerTex: SKTexture!
    private var bombTex: SKTexture!
    private var medalTex: [SKTexture] = []
    private var layoutS: Float = 1

    func setup(scene: SKScene) {
        self.scene = scene
        layoutS = LayoutPx.scale(width: scene.size.width, height: scene.size.height)
        powerTex = GameArt.texture("Images/item_powerup")
        bombTex = GameArt.texture("Images/item_bomb")
        medalTex = (0..<PowerUpItem.MEDAL_FRAME_COUNT).map {
            GameArt.texture("Images/item_medal_\($0)")
        }
        for _ in 0..<PowerUpItem.POOL_SIZE {
            let n = SKSpriteNode(texture: powerTex)
            n.zPosition = 52
            n.isHidden = true
            scene.addChild(n)
            nodes.append(n)
            ArcadeOutline.attach(to: n)
        }
    }

    func onSizeChanged(width: CGFloat, height: CGFloat) {
        layoutS = LayoutPx.scale(width: width, height: height)
    }

    func spawn(x: Float, y: Float) { spawn(x: x, y: y, type: PowerUpSlot.ITEM_TYPE_POWERUP) }

    func spawn(x: Float, y: Float, type: Int) {
        guard let s = firstFree() else { return }
        fill(s, x: x, y: y, type: type)
    }

    func spawnSway(x: Float, y: Float, type: Int) {
        guard let s = firstFree() else { return }
        fill(s, x: x, y: y, type: type)
        s.vx = 0; s.vy = PowerUpItem.SWAY_VY; s.homeX = x; s.swayT = 0; s.swayDrop = true
    }

    @discardableResult
    func spawnStationaryMedal(x: Float, y: Float, points: Int) -> Bool {
        guard let s = firstFree() else { return false }
        fill(s, x: x, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
        s.vx = 0; s.vy = 0; s.pickupPoints = points
        return true
    }

    func spawnSecretMedal(x: Float, y: Float) {
        guard let s = firstFree() else { return }
        fill(s, x: x, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
        s.vx = 0
        s.vy = 78
        s.pickupPoints = ScoreManager.SECRET_MEDAL_POINTS
        s.isSecretMedal = true
    }

    func update(dt: Float, screenW: Int, screenH: Int,
                playerX: Float, playerY: Float, magnetOn: Bool = true) {
        let floor = Float(screenH) + 48
        let edge  = Float(screenW) * PowerUpItem.EDGE_STRIP_FRAC
        let sceneH = scene.map { Float($0.size.height) } ?? Float(screenH)
        for i in 0..<PowerUpItem.POOL_SIZE {
            let s = pool[i]
            if s.isActive {
                if s.swayDrop {
                    s.swayT += dt
                    s.x = s.homeX + sinf(s.swayT * PowerUpItem.SWAY_RATE) * PowerUpItem.SWAY_AMP * layoutS
                    s.y += s.vy * dt
                } else {
                    s.x += s.vx * dt; s.y += s.vy * dt
                }
                if s.itemType != PowerUpSlot.ITEM_TYPE_MEDAL && !s.swayDrop {
                    if s.x <= 30 { s.x = 30; s.vx = -s.vx }
                    if s.x >= Float(screenW) - 30 { s.x = Float(screenW) - 30; s.vx = -s.vx }
                }
                if s.itemType == PowerUpSlot.ITEM_TYPE_MEDAL {
                    if magnetOn { pullMedal(s, dt: dt, px: playerX, py: playerY,
                                            edge: edge, sw: Float(screenW)) }
                    s.medalFrameTime += dt
                    while s.medalFrameTime >= PowerUpItem.MEDAL_FRAME_SEC {
                        s.medalFrameTime -= PowerUpItem.MEDAL_FRAME_SEC
                        s.medalFrameIndex = (s.medalFrameIndex + 1) % PowerUpItem.MEDAL_FRAME_COUNT
                    }
                }
                if s.y > floor { s.isActive = false }
            }
            syncNode(i, slot: s, sceneH: sceneH)
        }
    }

    private func syncNode(_ i: Int, slot s: PowerUpSlot, sceneH: Float) {
        guard i < nodes.count else { return }
        let n = nodes[i]
        if !s.isActive {
            n.isHidden = true
            return
        }
        n.isHidden = false
        n.position = CGPoint(x: CGFloat(s.x), y: CGFloat(sceneH - s.y))
        let hx: CGFloat
        if s.itemType == PowerUpSlot.ITEM_TYPE_MEDAL {
            hx = CGFloat(PowerUpItem.MEDAL_HALF * layoutS)
            let idx = min(max(s.medalFrameIndex, 0), medalTex.count - 1)
            if idx < medalTex.count { n.texture = medalTex[idx] }
            if s.isSecretMedal {
                n.color = UIColor(red: 1, green: 138.0/255, blue: 138.0/255, alpha: 1)
                n.colorBlendFactor = 1
            } else {
                n.color = .white
                n.colorBlendFactor = 0
            }
        } else if s.itemType == PowerUpSlot.ITEM_TYPE_BOMB {
            hx = CGFloat(PowerUpItem.POWERUP_HALF * layoutS)
            n.texture = bombTex
            n.color = .white
            n.colorBlendFactor = 0
        } else {
            hx = CGFloat(PowerUpItem.POWERUP_HALF * layoutS)
            n.texture = powerTex
            n.color = .white
            n.colorBlendFactor = 0
        }
        n.size = CGSize(width: hx * 2, height: hx * 2)
        ArcadeOutline.sync(n)
    }

    private func pullMedal(_ s: PowerUpSlot, dt: Float, px: Float, py: Float, edge: Float, sw: Float) {
        let dx = px - s.x; let dy = py - s.y
        let distSq = dx*dx + dy*dy
        var radius = PowerUpItem.MAGNET_RADIUS * layoutS
        if (s.x < edge && px < edge * 1.35) || (s.x > sw - edge && px > sw - edge * 1.35) {
            radius = PowerUpItem.MAGNET_EDGE_RADIUS * layoutS
        }
        if distSq > radius*radius || distSq <= 0.0001 { return }
        let dist = sqrtf(distSq)
        let step = PowerUpItem.MAGNET_SPEED * layoutS * dt
        if step >= dist { s.x = px; s.y = py; s.swayDrop = false }
        else { let inv = step/dist; s.x += dx*inv; s.y += dy*inv; s.swayDrop = false }
    }

    func deactivateAll() {
        pool.forEach { $0.isActive = false }
        nodes.forEach { $0.isHidden = true }
    }

    func drawHalf(forType type: Int) -> Float {
        let base = type == PowerUpSlot.ITEM_TYPE_MEDAL ? PowerUpItem.MEDAL_HALF : PowerUpItem.POWERUP_HALF
        return base * layoutS
    }

    private func firstFree() -> PowerUpSlot? { pool.first { !$0.isActive } }
    private func fill(_ s: PowerUpSlot, x: Float, y: Float, type: Int) {
        s.x = x; s.y = y
        if type == PowerUpSlot.ITEM_TYPE_MEDAL {
            s.vx = 0; s.vy = 110
        } else {
            s.vx = (Int(x) & 1) == 0 ? 120 : -120
            s.vy = 90
        }
        s.homeX = x; s.swayT = 0; s.swayDrop = false
        s.pickupPoints = 0; s.isSecretMedal = false; s.itemType = type
        s.medalFrameTime = 0; s.medalFrameIndex = 0
        s.isActive = true
    }
}

class PowerUpManager {
    static let instance = PowerUpManager()
    let items = PowerUpItem()
    private var lootSeed: UInt64 = 2463534242

    static let MEDAL_SCORE_FACE = 2000
    static let MEDAL_SCORE_EDGE = 200
    static let POWERUP_FULL_SCORE = 2000
    static let BOMB_FULL_SCORE = 5000
    static let RESPAWN_POWERUP_LIFT: Float = 160
    static let RESPAWN_POWERUP_MIN_Y: Float = 96

    func spawnGuaranteedDrop(x: Float, y: Float, itemType: Int) {
        items.spawnSway(x: x, y: y, type: itemType)
    }
    func spawnRightFlankDrop(x: Float, y: Float, playerWeaponPower: Int, bombStock: Int) {
        if playerWeaponPower < 3 { spawnGuaranteedDrop(x: x, y: y, itemType: ItemType.WEAPON_UP) }
        else if bombStock < 3  { spawnGuaranteedDrop(x: x, y: y, itemType: ItemType.BOMB_STOCK) }
        else                   { spawnGuaranteedDrop(x: x, y: y, itemType: ItemType.SHIELD_RECOVERY) }
    }
    func spawnBulletCancelDrop(x: Float, y: Float) {
        if !items.spawnStationaryMedal(x: x, y: y, points: ScoreManager.BULLET_CANCEL_POINTS) {
            ScoreManager.instance.addBulletCancelBonus(x: x, y: y)
        }
    }

    func dropEnemyLoot(x: Float, y: Float, enemyType: Int, guaranteedPowerup: Bool,
                       isMidBoss: Bool = false, bombStock: Int = 3, stageData: StageData) {
        if isMidBoss {
            items.spawn(x: x - 28, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
            items.spawn(x: x, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
            items.spawn(x: x + 28, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
            let extra = bombStock < 3 ? PowerUpSlot.ITEM_TYPE_BOMB : PowerUpSlot.ITEM_TYPE_POWERUP
            items.spawn(x: x, y: y + 36, type: extra)
            return
        }
        items.spawn(x: x, y: y, type: PowerUpSlot.ITEM_TYPE_MEDAL)
        if guaranteedPowerup {
            items.spawn(x: x, y: y, type: PowerUpSlot.ITEM_TYPE_POWERUP)
            return
        }
        let armored = enemyType == EnemyPoolManager.TYPE_HEAVY
            || enemyType == EnemyPoolManager.TYPE_INTERCEPTOR
        var dropChance: Float = armored ? 0.40 : 0.15
        dropChance *= stageData.lootChanceScale()
        let cap: Float = armored ? 0.50 : 0.20
        if dropChance > cap { dropChance = cap }
        if nextLootUnit() >= dropChance { return }
        let pickupType = nextLootUnit() < 0.2
            ? PowerUpSlot.ITEM_TYPE_BOMB
            : PowerUpSlot.ITEM_TYPE_POWERUP
        items.spawn(x: x, y: y, type: pickupType)
    }

    private func nextLootUnit() -> Float {
        lootSeed = lootSeed &* 1664525 &+ 1013904223
        return Float((lootSeed >> 8) & 0xFFFFFF) / 16777215.0
    }
}
