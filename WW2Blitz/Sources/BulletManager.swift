import SpriteKit

class BulletManager {
    private let poolSize = 100
    private(set) var bulletPool: [PlayerBullet]

    private var fireCooldownTimer: Float = 0
    private var missileCooldown: Float   = 0
    private var spawnedStreamFlag: Bool  = false

    // SpriteKit rendering
    private weak var scene: SKScene?
    private var bulletNodes: [SKShapeNode] = []
    private var screenW: Float = 0
    private var screenH: Float = 0
    private var layoutS: Float = 1

    static let HALF_BULLET_WIDTH:  Float = 6
    static let HALF_BULLET_HEIGHT: Float = 16
    static let MISSILE_INTERVAL:   Float = 0.480
    static let SPARK_SPEED: Float   = 280
    static let SPARK_FALLBACK_VY: Float = -280
    static let P38_WING_OFFSET_X: Float = 18
    static let P38_MUZZLE_OFFSET_Y: Float = 10
    static let P38_VY: Float            = -1600
    static let HELLCAT_CENTER_VY: Float = -1350
    static let HELLCAT_FLANK_VX: Float  = 280.68
    static let HELLCAT_FLANK_VY: Float  = -1320.55

    init() {
        bulletPool = (0..<poolSize).map { _ in PlayerBullet() }
    }

    func setup(scene: SKScene) {
        self.scene = scene
        onSizeChanged(width: scene.size.width, height: scene.size.height)
        // Pre-create bullet nodes (Android 6×16 px, scaled to scene points)
        let hw = CGFloat(BulletManager.HALF_BULLET_WIDTH * layoutS)
        let hh = CGFloat(BulletManager.HALF_BULLET_HEIGHT * layoutS)
        for _ in 0..<poolSize {
            let path = CGPath(roundedRect: CGRect(x: -hw, y: -hh, width: hw * 2, height: hh * 2),
                              cornerWidth: hw, cornerHeight: hw, transform: nil)
            let n = SKShapeNode(path: path)
            n.fillColor = .yellow; n.strokeColor = .clear
            n.zPosition = 40; n.isHidden = true
            scene.addChild(n)
            bulletNodes.append(n)
        }
    }

    func onSizeChanged(width: CGFloat, height: CGFloat) {
        screenW = Float(width); screenH = Float(height)
        layoutS = LayoutPx.scale(width: width, height: height)
        let hw = CGFloat(BulletManager.HALF_BULLET_WIDTH * layoutS)
        let hh = CGFloat(BulletManager.HALF_BULLET_HEIGHT * layoutS)
        let path = CGPath(roundedRect: CGRect(x: -hw, y: -hh, width: hw * 2, height: hh * 2),
                          cornerWidth: hw, cornerHeight: hw, transform: nil)
        for n in bulletNodes { n.path = path }
    }

    func update(dt: Float, player: PlayerShip, screenW: Int, homingMissiles: HomingMissileManager) {
        spawnedStreamFlag = false
        if fireCooldownTimer > 0 { fireCooldownTimer -= dt }
        if missileCooldown   > 0 { missileCooldown   -= dt }

        let held = player.isFiringHeld()
        if held && fireCooldownTimer <= 0 {
            spawnWeaponStream(player)
            spawnedStreamFlag = true
            fireCooldownTimer = player.vulcanInterval()
        }
        if player.getWeaponPower() >= 3 && held && missileCooldown <= 0 {
            let s = layoutS
            let mx = player.getHitboxX()
            let my = screenH - player.getHitboxY()
            homingMissiles.fireMissile(startX: mx - 30 * s, startY: my, initVx: -150 * s, initVy: -400 * s)
            homingMissiles.fireMissile(startX: mx + 30 * s, startY: my, initVx:  150 * s, initVy: -400 * s)
            missileCooldown = BulletManager.MISSILE_INTERVAL
        }

        let maxX = Float(screenW) + 40
        let sceneH = scene.map { Float($0.size.height) } ?? 0
        for i in 0..<poolSize {
            let b = bulletPool[i]
            if b.isActive {
                b.x += b.vx * dt; b.y += b.vy * dt
                // Android top-origin => bullets with vy < 0 go up => in SpriteKit vy > 0 means up
                // We store velocity in Android coordinate space (y down), convert for display
                if b.y < 0 || b.x < -40 || b.x > maxX {
                    b.isActive = false
                }
            }
            let n = bulletNodes[i]
            if b.isActive {
                n.isHidden = false
                n.position = CGPoint(x: CGFloat(b.x), y: CGFloat(sceneH - b.y))
            } else { n.isHidden = true }
        }
    }

    private func spawnWeaponStream(_ player: PlayerShip) {
        let s = layoutS
        let sx = player.getHitboxX()
        // PlayerShip stores SpriteKit y-up; gameplay bullets use Android y-down like enemies.
        let sy = screenH - player.getHitboxY()
        if player.chosenFighterIndex == 1 {
            let my = sy - 15 * s
            spawnPlayerBullet(x: sx, y: my, vx: 0, vy: BulletManager.HELLCAT_CENTER_VY * s)
            spawnPlayerBullet(x: sx, y: my, vx: -BulletManager.HELLCAT_FLANK_VX * s,
                              vy: BulletManager.HELLCAT_FLANK_VY * s)
            spawnPlayerBullet(x: sx, y: my, vx:  BulletManager.HELLCAT_FLANK_VX * s,
                              vy: BulletManager.HELLCAT_FLANK_VY * s)
        } else {
            let my = sy - BulletManager.P38_MUZZLE_OFFSET_Y * s
            spawnPlayerBullet(x: sx - BulletManager.P38_WING_OFFSET_X * s, y: my, vx: 0,
                              vy: BulletManager.P38_VY * s)
            spawnPlayerBullet(x: sx + BulletManager.P38_WING_OFFSET_X * s, y: my, vx: 0,
                              vy: BulletManager.P38_VY * s)
        }
        SoundManager.instance.playSFX(SoundManager.SFX_VULCAN)
    }

    func spawnPlayerBullet(x: Float, y: Float, vx: Float, vy: Float) {
        for b in bulletPool {
            if !b.isActive {
                b.x = x; b.y = y; b.vx = vx; b.vy = vy; b.isActive = true; return
            }
        }
    }

    func getPoolSize() -> Int { poolSize }
    func didSpawnStream() -> Bool { spawnedStreamFlag }
    func deactivateAll() {
        bulletPool.forEach { $0.isActive = false }
        bulletNodes.forEach { $0.isHidden = true }
    }

    func resolveEnemyBulletsVsPlayer(
        player: PlayerShip,
        enemyBullets: [EnemyBullet],
        enemyBulletCount: Int,
        particles: ParticleManager,
        awardScore: Bool
    ) -> Bool {
        if !player.isOnField() { return false }
        let px = player.centerX(); let py = player.worldY()
        let coreR = player.coreHitboxRadius
        let grazeR = player.grazeRadius
        let hitR = coreR + EnemyWeaponSystem.BULLET_HIT_RADIUS
        let hitSq = hitR * hitR
        let grazeSq = grazeR * grazeR
        var damagedThisFrame = false
        for i in 0..<enemyBulletCount {
            let b = enemyBullets[i]; guard b.isActive else { continue }
            let dx = b.x - px; let dy = b.y - py
            if (b.flags & EnemyBullet.FLAG_LASER) != 0 {
                let hw = EnemyWeaponSystem.S6_LASER_HW + coreR
                let hh = EnemyWeaponSystem.S6_LASER_HH + coreR
                if dx <= hw && dx >= -hw && dy <= hh && dy >= -hh {
                    b.isActive = false; b.flags = 0
                    if !damagedThisFrame {
                        damagedThisFrame = true
                        if player.takeDamage() {
                            particles.triggerExplosion(x: px, y: py)
                            if player.isGameOver() { return true }
                        }
                    }
                }
            } else {
                let distSq = dx*dx + dy*dy
                if distSq <= hitSq {
                    b.isActive = false; b.flags = 0
                    if !damagedThisFrame {
                        damagedThisFrame = true
                        if player.takeDamage() {
                            particles.triggerExplosion(x: px, y: py)
                            if player.isGameOver() { return true }
                        }
                    }
                } else if distSq <= grazeSq && (b.flags & EnemyBullet.FLAG_GRAZED) == 0 {
                    b.flags |= EnemyBullet.FLAG_GRAZED
                    if awardScore { ScoreManager.instance.addGrazeScore(ScoreManager.GRAZE_POINTS) }
                    var sparkVx: Float = 0; var sparkVy = BulletManager.SPARK_FALLBACK_VY
                    if distSq > 0.0001 {
                        let inv = BulletManager.SPARK_SPEED / sqrtf(distSq)
                        sparkVx = dx * inv; sparkVy = dy * inv
                    }
                    particles.triggerSpark(x: b.x, y: b.y, vx: sparkVx, vy: sparkVy)
                }
            }
        }
        return false
    }
}
