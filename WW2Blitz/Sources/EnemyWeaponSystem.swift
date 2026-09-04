import SpriteKit

class EnemyWeaponSystem {
    private(set) var pool: [EnemyBullet]

    private var screenW: Float = 0
    private var screenH: Float = 0

    private var clearX = [Float](repeating: 0, count: CLEAR_SLOTS)
    private var clearY = [Float](repeating: 0, count: CLEAR_SLOTS)
    private var clearT = [Float](repeating: 0, count: CLEAR_SLOTS)

    // Boss fire timers (all 8 bosses)
    private var turretTimer: Float = 0
    private var coreVentTimer: Float = 0
    private var magmaTimer: Float = 0
    private var spiralAngle: Float = 0
    private var spiralGate: Float = S6_SPIRAL_INTERVAL
    private var s5RingAlt: Int = 0
    private var s5MagmaSeed: UInt64 = 1
    private var s6RailAlt: Int = 0
    private var s6LaserTimer: Float = S6_WAVE_INTERVAL
    private var s6RingTimer: Float  = S6_RING_INTERVAL
    private var s6BurstRemaining: Int = 0
    private var s6BurstGap: Float = S6_BURST_GAP
    private var s6ColumnRemaining: Int = 0
    private var s6ColumnGap: Float = S6_BURST_GAP
    private var s1NoseTimer: Float = 0
    private var s1WingTimer: Float = 0
    private var s2MainTimer: Float = 0
    private var s2TreadTimer: Float = 0
    private var s3FlakTimer: Float = 0
    private var s3CannonTimer: Float = 0
    private var s3FlakLeft: Bool = true
    private var s4MortarTimer: Float = 0
    private var s4GatlingTimer: Float = 0
    private var s7HowitzerTimer: Float = 0
    private var s7BlizzardTimer: Float = 0
    private var s7HowitzerLeft: Bool = true
    private var s8CoastalTimer: Float = 0
    private var s8AaTimer: Float = 0
    private var s8CoastalLeft: Bool = true

    // SpriteKit rendering
    private weak var scene: SKScene?
    private var bulletNodes: [SKShapeNode] = []

    static let POOL_SIZE = 720
    static let HALF_BULLET_WIDTH:  Float = 18
    static let HALF_BULLET_HEIGHT: Float = 18
    static let GLOW_INSET: Float = 5
    static let BULLET_HIT_RADIUS: Float  = 10
    static let CLEAR_SLOTS = 4
    static let CLEAR_RADIUS: Float = 150
    static let CLEAR_LIFE: Float   = 0.15

    // Stage weapon constants
    static let S1_NOSE_INTERVAL: Float = 0.22
    static let S1_WING_INTERVAL: Float = 1.5
    static let S1_NOSE_SPEED: Float    = 620
    static let S1_WING_SPEED: Float    = 420
    static let S1_ANG_75: Float  = 1.309
    static let S1_ANG_90: Float  = 1.5707964
    static let S1_ANG_105: Float = 1.8326
    static let S2_MAIN_INTERVAL: Float   = 1.50
    static let S2_TREAD_INTERVAL: Float  = 2.20
    static let TANK_SHOT_SPEED: Float    = 700
    static let TANK_BARREL_SEP: Float    = 32
    static let S2_DOWN_ANGLE: Float      = 1.5707964  // π/2, pointing down
    static let S2_SPONSON_SPEED: Float   = 480
    static let S2_SPONSON_STEP: Float    = 0.2617994
    static let S3_FLAK_INTERVAL: Float   = 0.60
    static let S3_CANNON_INTERVAL: Float = 3.00
    static let S3_FLAK_SPEED: Float      = 560
    static let S3_FLAK_SEP: Float        = 8
    static let S3_WALL_COUNT = 7
    static let S3_WALL_HALF: Float  = 0.5235988
    static let S3_WALL_STEP: Float  = 0.1745329
    static let S3_WALL_SPEED: Float = 400
    static let S4_MORTAR_INTERVAL: Float  = 1.20
    static let S4_GATLING_INTERVAL: Float = 0.90
    static let S4_FAN_STEP: Float  = 0.2618
    static let S4_FAN_HALF: Float  = 0.2618
    static let S4_MORTAR_SPEED: Float = 580
    static let S7_HOWITZER_INTERVAL: Float = 1.05
    static let S7_HOWITZER_SPEED: Float    = 520
    static let S7_BLIZZARD_INTERVAL: Float = 1.35
    static let S7_BLIZZARD_SPEED: Float    = 360
    static let S7_BLIZZARD_STEP: Float     = 0.1745329
    static let S7_LEFT_MUZZLE_X: Float   = -0.2715
    static let S7_LEFT_MUZZLE_Y: Float   =  0.1592
    static let S7_RIGHT_MUZZLE_X: Float  =  0.2656
    static let S7_RIGHT_MUZZLE_Y: Float  =  0.1592
    static let S7_CHIN_MUZZLE_X: Float   = -0.0029
    static let S7_CHIN_MUZZLE_Y: Float   =  0.4512
    static let S8_COASTAL_INTERVAL: Float = 0.95
    static let S8_COASTAL_SPEED: Float    = 540
    static let S8_AA_INTERVAL: Float      = 1.10
    static let S8_AA_SPEED: Float         = 480
    static let S8_AA_STEP: Float          = 0.1745329
    static let S8_LEFT_MUZZLE_X: Float    = -0.3252
    static let S8_LEFT_MUZZLE_Y: Float    =  0.1025
    static let S8_RIGHT_MUZZLE_X: Float   =  0.3242
    static let S8_RIGHT_MUZZLE_Y: Float   =  0.1016
    static let S8_AA_LEFT_X: Float   = -0.0449
    static let S8_AA_LEFT_Y: Float   =  0.4561
    static let S8_AA_RIGHT_X: Float  =  0.0352
    static let S8_AA_RIGHT_Y: Float  =  0.4561
    static let S5_VOLLEY_INTERVAL: Float   = 1.8
    static let S5_PANIC_INTERVAL: Float    = 0.9
    static let S5_RING_INTERVAL: Float     = 3.0
    static let S5_VOLLEY_VY: Float         = 400
    static let S5_BARREL_SEP: Float        = 14
    static let S5_RING_SPEED: Float        = 360
    static let S5_FAN_STEP: Float          = 0.1745329
    static let S5_FAN_SPEED: Float         = 480
    static let S5_MAGMA_INTERVAL: Float    = 1.5
    static let S5_MAGMA_VY: Float          = 190
    static let S5_SPIRAL_SPIN: Float       = 6.5
    static let S5_SPIRAL_INTERVAL: Float   = 0.15
    static let S5_SPIRAL_SPEED: Float      = 440
    static let S6_RAIL_INTERVAL: Float     = 1.4
    static let S6_BURST_COUNT   = 3
    static let S6_BURST_GAP: Float         = 0.22
    static let S6_BURST_SPEED: Float       = 500
    static let S6_OVERCHARGE_INTERVAL: Float = 0.4
    static let S6_STREAM_SPEED: Float      = 500
    static let S6_WAVE_INTERVAL: Float     = 2.5
    static let S6_CORE_SHOTS    = 4
    static let S6_CORE_VY: Float           = 220
    static let S6_RING_INTERVAL: Float     = 1.8
    static let S6_SPIRAL_INTERVAL: Float   = 0.08
    static let S6_SPIRAL_SPIN: Float       = 9.5
    static let S6_HELIX_A1: Float = 1.57
    static let S6_HELIX_A2: Float = 3.14
    static let S6_HELIX_A3: Float = 4.71
    static let S6_LASER_HW: Float = 28
    static let S6_LASER_HH: Float = 6
    static let S6_RING_COUNT = 12
    static let S6_RING_STEP: Float = 0.5235988
    static let S6_RING_SPEED: Float = 340
    static let S6_SPIRAL_SPEED: Float = 480

    // S1_SWEEP (boss-internal constants used elsewhere)
    static let S1_SWEEP_INTERVAL: Float = 0.16
    static let S1_SWEEP_SPEED: Float    = 480
    static let S1_SWEEP_FREQ: Float     = 3.5
    static let S1_SWEEP_AMP: Float      = 0.6
    static let S1_SWEEP_ARC_STEP: Float = 0.12

    init() {
        pool = (0..<EnemyWeaponSystem.POOL_SIZE).map { _ in EnemyBullet() }
    }

    func setup(scene: SKScene) {
        self.scene = scene
        onSizeChanged(width: Int(scene.size.width), height: Int(scene.size.height))
        let s = CGFloat(LayoutPx.scale(width: scene.size.width, height: scene.size.height))
        let hw = CGFloat(EnemyWeaponSystem.HALF_BULLET_WIDTH) * s
        let hh = CGFloat(EnemyWeaponSystem.HALF_BULLET_HEIGHT) * s
        let inset = CGFloat(EnemyWeaponSystem.GLOW_INSET) * s
        for _ in 0..<EnemyWeaponSystem.POOL_SIZE {
            let n = SKShapeNode(ellipseIn: CGRect(x: -hw, y: -hh, width: hw*2, height: hh*2))
            n.fillColor = UIColor(red: 0, green: 1, blue: 0.4, alpha: 1)
            n.strokeColor = .clear; n.zPosition = 37; n.isHidden = true
            let ih = max(hw - inset, 1)
            let iv = max(hh - inset, 1)
            let glow = SKShapeNode(ellipseIn: CGRect(x: -ih, y: -iv, width: ih*2, height: iv*2))
            glow.fillColor = .white
            glow.strokeColor = .clear
            glow.zPosition = 1
            glow.name = "glow"
            n.addChild(glow)
            scene.addChild(n); bulletNodes.append(n)
        }
    }

    func onSizeChanged(width: Int, height: Int) {
        screenW = Float(width); screenH = Float(height)
        let s = CGFloat(LayoutPx.scale(width: CGFloat(width), height: CGFloat(height)))
        let hw = CGFloat(EnemyWeaponSystem.HALF_BULLET_WIDTH) * s
        let hh = CGFloat(EnemyWeaponSystem.HALF_BULLET_HEIGHT) * s
        let inset = CGFloat(EnemyWeaponSystem.GLOW_INSET) * s
        let path = CGPath(ellipseIn: CGRect(x: -hw, y: -hh, width: hw*2, height: hh*2), transform: nil)
        let ih = max(hw - inset, 1)
        let iv = max(hh - inset, 1)
        let glowPath = CGPath(ellipseIn: CGRect(x: -ih, y: -iv, width: ih*2, height: iv*2), transform: nil)
        for n in bulletNodes {
            n.path = path
            (n.childNode(withName: "glow") as? SKShapeNode)?.path = glowPath
        }
    }

    func getPoolSize() -> Int { EnemyWeaponSystem.POOL_SIZE }

    func deactivateAll() {
        pool.forEach { $0.isActive = false; $0.flags = 0 }
        for i in 0..<EnemyWeaponSystem.CLEAR_SLOTS { clearT[i] = 0 }
        for n in bulletNodes {
            n.isHidden = true
            n.childNode(withName: "glow")?.isHidden = true
        }
    }

    func convertActiveToScoreItems() {
        for b in pool where b.isActive {
            PowerUpManager.instance.spawnBulletCancelDrop(x: b.x, y: b.y)
            b.isActive = false; b.flags = 0; b.vx = 0; b.vy = 0
        }
    }

    func beginDeathClear(originX: Float, originY: Float) {
        for i in 0..<EnemyWeaponSystem.CLEAR_SLOTS {
            if clearT[i] <= 0 {
                clearX[i] = originX; clearY[i] = originY; clearT[i] = EnemyWeaponSystem.CLEAR_LIFE; return
            }
        }
        clearX[0] = originX; clearY[0] = originY; clearT[0] = EnemyWeaponSystem.CLEAR_LIFE
    }

    func fireBullet(startX: Float, startY: Float, velX: Float, velY: Float, flags: Int = 0) {
        for b in pool where !b.isActive {
            b.x = startX; b.y = startY; b.vx = velX; b.vy = velY; b.flags = flags; b.isActive = true; return
        }
    }

    // MARK: - Boss weapon resets

    func resetStage1Boss() { s1NoseTimer = scaledInterval(EnemyWeaponSystem.S1_NOSE_INTERVAL); s1WingTimer = scaledInterval(EnemyWeaponSystem.S1_WING_INTERVAL) }
    func resetStage2Boss() { s2MainTimer = scaledInterval(EnemyWeaponSystem.S2_MAIN_INTERVAL); s2TreadTimer = scaledInterval(EnemyWeaponSystem.S2_TREAD_INTERVAL) }
    func resetStage3Boss() { s3FlakTimer = scaledInterval(EnemyWeaponSystem.S3_FLAK_INTERVAL); s3CannonTimer = scaledInterval(EnemyWeaponSystem.S3_CANNON_INTERVAL); s3FlakLeft = true }
    func resetStage4Boss() { s4MortarTimer = scaledInterval(EnemyWeaponSystem.S4_MORTAR_INTERVAL); s4GatlingTimer = scaledInterval(EnemyWeaponSystem.S4_GATLING_INTERVAL) }
    func resetStage5Boss() { turretTimer = scaledInterval(EnemyWeaponSystem.S5_VOLLEY_INTERVAL); coreVentTimer = scaledInterval(EnemyWeaponSystem.S5_RING_INTERVAL); magmaTimer = 0; spiralAngle = 0; spiralGate = 0; s5RingAlt = 0 }
    func resetStage6Boss() { turretTimer = scaledInterval(EnemyWeaponSystem.S6_RAIL_INTERVAL); s6LaserTimer = scaledInterval(EnemyWeaponSystem.S6_WAVE_INTERVAL); s6RingTimer = scaledInterval(EnemyWeaponSystem.S6_RING_INTERVAL); spiralAngle = 0; spiralGate = scaledInterval(EnemyWeaponSystem.S6_SPIRAL_INTERVAL); s6RailAlt = 0; s6BurstRemaining = 0; s6BurstGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP); s6ColumnRemaining = 0; s6ColumnGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP) }
    func resetStage7Boss() { s7HowitzerTimer = scaledInterval(EnemyWeaponSystem.S7_HOWITZER_INTERVAL); s7BlizzardTimer = scaledInterval(EnemyWeaponSystem.S7_BLIZZARD_INTERVAL); s7HowitzerLeft = true }
    func resetStage8Boss() { s8CoastalTimer = scaledInterval(EnemyWeaponSystem.S8_COASTAL_INTERVAL); s8AaTimer = scaledInterval(EnemyWeaponSystem.S8_AA_INTERVAL); s8CoastalLeft = true }

    // MARK: - Boss weapon update methods

    func updateStage1Boss(dt: Float, centerX: Float, centerY: Float, bossW: Float,
                          playerX: Float, playerY: Float, leftWingDead: Bool, rightWingDead: Bool) {
        s1NoseTimer -= dt
        if s1NoseTimer <= 0 {
            s1NoseTimer = scaledInterval(EnemyWeaponSystem.S1_NOSE_INTERVAL)
            let ny = centerY + bossW * 0.48
            let ang = atan2f(playerY - ny, playerX - centerX)
            let spd = scaledSpeed(EnemyWeaponSystem.S1_NOSE_SPEED)
            fireBullet(startX: centerX, startY: ny, velX: cosf(ang)*spd, velY: sinf(ang)*spd)
        }
        if leftWingDead && rightWingDead { return }
        s1WingTimer -= dt
        if s1WingTimer > 0 { return }
        s1WingTimer = scaledInterval(EnemyWeaponSystem.S1_WING_INTERVAL)
        let wy = centerY + bossW * 0.05
        if !leftWingDead  { fireS1WingSpread(x: centerX - bossW * 0.25, y: wy) }
        if !rightWingDead { fireS1WingSpread(x: centerX + bossW * 0.25, y: wy) }
    }
    private func fireS1WingSpread(x: Float, y: Float) {
        let spd = scaledSpeed(EnemyWeaponSystem.S1_WING_SPEED)
        fireBullet(startX: x, startY: y, velX: cosf(EnemyWeaponSystem.S1_ANG_75)*spd, velY: sinf(EnemyWeaponSystem.S1_ANG_75)*spd)
        fireBullet(startX: x, startY: y, velX: cosf(EnemyWeaponSystem.S1_ANG_90)*spd, velY: sinf(EnemyWeaponSystem.S1_ANG_90)*spd)
        fireBullet(startX: x, startY: y, velX: cosf(EnemyWeaponSystem.S1_ANG_105)*spd, velY: sinf(EnemyWeaponSystem.S1_ANG_105)*spd)
    }

    func updateStage2Boss(dt: Float, cX: Float, cY: Float, w: Float, pX: Float, pY: Float,
                          leftTreadDead: Bool, rightTreadDead: Bool, turretDead: Bool) {
        if !turretDead {
            s2MainTimer -= dt
            if s2MainTimer <= 0 {
                s2MainTimer = scaledInterval(EnemyWeaponSystem.S2_MAIN_INTERVAL)
                let spd = scaledSpeed(EnemyWeaponSystem.TANK_SHOT_SPEED)
                let by = cY + w * 0.45
                fireBullet(startX: cX - EnemyWeaponSystem.TANK_BARREL_SEP, startY: by, velX: 0, velY: spd)
                fireBullet(startX: cX + EnemyWeaponSystem.TANK_BARREL_SEP, startY: by, velX: 0, velY: spd)
            }
        }
        if leftTreadDead && rightTreadDead { return }
        s2TreadTimer -= dt
        if s2TreadTimer > 0 { return }
        s2TreadTimer = scaledInterval(EnemyWeaponSystem.S2_TREAD_INTERVAL)
        let ty = cY + w * 0.10
        if !leftTreadDead  { fireS2SponsonFan(x: cX - w * 0.35, y: ty, downAndLeft: true) }
        if !rightTreadDead { fireS2SponsonFan(x: cX + w * 0.35, y: ty, downAndLeft: false) }
    }
    private func fireS2SponsonFan(x: Float, y: Float, downAndLeft: Bool) {
        let spd = scaledSpeed(EnemyWeaponSystem.S2_SPONSON_SPEED)
        for i in 0..<4 {
            let ang: Float = downAndLeft ? EnemyWeaponSystem.S2_DOWN_ANGLE + Float(i) * EnemyWeaponSystem.S2_SPONSON_STEP
                                         : EnemyWeaponSystem.S2_DOWN_ANGLE - Float(i) * EnemyWeaponSystem.S2_SPONSON_STEP
            fireBullet(startX: x, startY: y, velX: cosf(ang)*spd, velY: sinf(ang)*spd)
        }
    }

    func updateStage3Boss(dt: Float, cX: Float, cY: Float, w: Float, pX: Float, pY: Float,
                          leftFlakDead: Bool, rightFlakDead: Bool, cannonDead: Bool) {
        if !leftFlakDead || !rightFlakDead {
            s3FlakTimer -= dt
            if s3FlakTimer <= 0 {
                s3FlakTimer = scaledInterval(EnemyWeaponSystem.S3_FLAK_INTERVAL)
                let sy = cY + w * 0.025
                if s3FlakLeft && !leftFlakDead       { fireS3FlakBurst(x: cX - w*0.29, y: sy, pX: pX, pY: pY) }
                else if !s3FlakLeft && !rightFlakDead { fireS3FlakBurst(x: cX + w*0.29, y: sy, pX: pX, pY: pY) }
                else if !leftFlakDead                 { fireS3FlakBurst(x: cX - w*0.29, y: sy, pX: pX, pY: pY) }
                else                                  { fireS3FlakBurst(x: cX + w*0.29, y: sy, pX: pX, pY: pY) }
                s3FlakLeft = !s3FlakLeft
            }
        }
        if cannonDead { return }
        s3CannonTimer -= dt; if s3CannonTimer > 0 { return }
        s3CannonTimer = scaledInterval(EnemyWeaponSystem.S3_CANNON_INTERVAL)
        let spd = scaledSpeed(EnemyWeaponSystem.S3_WALL_SPEED)
        let oy = cY + w * 0.46
        for i in 0..<EnemyWeaponSystem.S3_WALL_COUNT {
            let ang = EnemyWeaponSystem.S2_DOWN_ANGLE - EnemyWeaponSystem.S3_WALL_HALF + Float(i) * EnemyWeaponSystem.S3_WALL_STEP
            fireBullet(startX: cX, startY: oy, velX: cosf(ang)*spd, velY: sinf(ang)*spd)
        }
    }
    private func fireS3FlakBurst(x: Float, y: Float, pX: Float, pY: Float) {
        fireS3Aimed(ox: x - EnemyWeaponSystem.S3_FLAK_SEP, oy: y, tX: pX, tY: pY)
        fireS3Aimed(ox: x, oy: y, tX: pX, tY: pY)
        fireS3Aimed(ox: x + EnemyWeaponSystem.S3_FLAK_SEP, oy: y, tX: pX, tY: pY)
    }
    private func fireS3Aimed(ox: Float, oy: Float, tX: Float, tY: Float) {
        let dx = tX-ox; let dy = tY-oy; let lenSq = dx*dx+dy*dy
        if lenSq < 0.0001 { return }
        let inv = scaledSpeed(EnemyWeaponSystem.S3_FLAK_SPEED) / sqrtf(lenSq)
        fireBullet(startX: ox, startY: oy, velX: dx*inv, velY: dy*inv)
    }

    func updateStage4Boss(dt: Float, cX: Float, cY: Float, bossW: Float, bossHalfH: Float,
                          pX: Float, pY: Float, leftMortarDead: Bool, rightMortarDead: Bool, gatlingDead: Bool) {
        if !leftMortarDead || !rightMortarDead {
            s4MortarTimer -= dt
            if s4MortarTimer <= 0 {
                s4MortarTimer = scaledInterval(EnemyWeaponSystem.S4_MORTAR_INTERVAL)
                if !leftMortarDead  { fireS4MortarFan(x: cX - bossW*0.16, y: cY + bossHalfH*0.28, downRight: true) }
                if !rightMortarDead { fireS4MortarFan(x: cX + bossW*0.16, y: cY + bossHalfH*0.28, downRight: false) }
            }
        }
        if gatlingDead { return }
        s4GatlingTimer -= dt; if s4GatlingTimer > 0 { return }
        s4GatlingTimer = scaledInterval(EnemyWeaponSystem.S4_GATLING_INTERVAL)
        let sy = cY + bossHalfH * 0.88
        let spd = scaledSpeed(720)
        for idx in -2...2 { fireBullet(startX: cX + Float(idx)*24, startY: sy, velX: 0, velY: spd) }
    }
    private func fireS4MortarFan(x: Float, y: Float, downRight: Bool) {
        let base = downRight ? EnemyWeaponSystem.S2_DOWN_ANGLE - EnemyWeaponSystem.S4_FAN_HALF
                             : EnemyWeaponSystem.S2_DOWN_ANGLE + EnemyWeaponSystem.S4_FAN_HALF
        let spd = scaledSpeed(EnemyWeaponSystem.S4_MORTAR_SPEED)
        for i in -1...1 { let ang = base + Float(i)*EnemyWeaponSystem.S4_FAN_STEP; fireBullet(startX: x, startY: y, velX: cosf(ang)*spd, velY: sinf(ang)*spd) }
    }

    func updateStage5Boss(dt: Float, centerX: Float, centerY: Float, bossWidth: Float,
                          playerX: Float, playerY: Float, leftDestroyed: Bool, rightDestroyed: Bool) {
        let ltX = centerX - 0.38*bossWidth; let ltY = centerY
        let rtX = centerX + 0.38*bossWidth; let rtY = centerY
        let cvX = centerX; let cvY = centerY + 0.10*bossWidth
        if !leftDestroyed && !rightDestroyed {
            turretTimer -= dt
            if turretTimer <= 0 { turretTimer = scaledInterval(EnemyWeaponSystem.S5_VOLLEY_INTERVAL); fireS5DownSpread(ox: ltX, oy: ltY); fireS5DownSpread(ox: rtX, oy: rtY) }
            coreVentTimer -= dt
            if coreVentTimer <= 0 { coreVentTimer = scaledInterval(EnemyWeaponSystem.S5_RING_INTERVAL); fireS5Ring(ox: cvX, oy: cvY) }
            return
        }
        if !leftDestroyed || !rightDestroyed {
            turretTimer -= dt
            if turretTimer <= 0 {
                turretTimer = scaledInterval(EnemyWeaponSystem.S5_PANIC_INTERVAL)
                if !leftDestroyed { fireS5PlayerFan(ox: ltX, oy: ltY, pX: playerX, pY: playerY) }
                else              { fireS5PlayerFan(ox: rtX, oy: rtY, pX: playerX, pY: playerY) }
            }
            magmaTimer -= dt
            if magmaTimer <= 0 {
                magmaTimer = scaledInterval(EnemyWeaponSystem.S5_MAGMA_INTERVAL)
                for _ in 0..<3 {
                    s5MagmaSeed = s5MagmaSeed &* 1664525 &+ 1013904223
                    let u = Float((s5MagmaSeed >> 8) & 0xFFFFFF) / 16777215.0
                    fireBullet(startX: cvX + (u*0.30 - 0.15)*bossWidth, startY: cvY, velX: 0, velY: scaledSpeed(EnemyWeaponSystem.S5_MAGMA_VY))
                }
            }
            return
        }
        spiralAngle += EnemyWeaponSystem.S5_SPIRAL_SPIN * dt
        spiralGate -= dt
        if spiralGate <= 0 { spiralGate = scaledInterval(EnemyWeaponSystem.S5_SPIRAL_INTERVAL); fireS5SpiralPair(ox: cvX, oy: cvY, ang: spiralAngle); fireS5SpiralPair(ox: cvX, oy: cvY, ang: -spiralAngle) }
    }
    private func fireS5DownSpread(ox: Float, oy: Float) {
        for i in 0..<3 { fireBullet(startX: ox + Float(i-1)*EnemyWeaponSystem.S5_BARREL_SEP, startY: oy, velX: 0, velY: scaledSpeed(EnemyWeaponSystem.S5_VOLLEY_VY)) }
    }
    private func fireS5Ring(ox: Float, oy: Float) {
        let step = Float.pi * 2 / 8; let phase: Float = s5RingAlt == 0 ? 0 : step * 0.5
        s5RingAlt = s5RingAlt == 0 ? 1 : 0
        let spd = scaledSpeed(EnemyWeaponSystem.S5_RING_SPEED)
        for i in 0..<8 { let a = phase + Float(i)*step; fireBullet(startX: ox, startY: oy, velX: cosf(a)*spd, velY: sinf(a)*spd) }
    }
    private func fireS5PlayerFan(ox: Float, oy: Float, pX: Float, pY: Float) {
        let base = atan2f(pY-oy, pX-ox); let spd = scaledSpeed(EnemyWeaponSystem.S5_FAN_SPEED)
        for i in 0..<5 { let a = base + Float(i-2)*EnemyWeaponSystem.S5_FAN_STEP; fireBullet(startX: ox, startY: oy, velX: cosf(a)*spd, velY: sinf(a)*spd) }
    }
    private func fireS5SpiralPair(ox: Float, oy: Float, ang: Float) {
        let spd = scaledSpeed(EnemyWeaponSystem.S5_SPIRAL_SPEED)
        fireBullet(startX: ox, startY: oy, velX: cosf(ang)*spd, velY: sinf(ang)*spd)
        fireBullet(startX: ox, startY: oy, velX: cosf(ang + Float.pi)*spd, velY: sinf(ang + Float.pi)*spd)
    }

    func updateStage6Boss(dt: Float, leftX: Float, leftY: Float, rightX: Float, rightY: Float,
                          lensX: Float, lensY: Float, playerX: Float, playerY: Float,
                          leftDestroyed: Bool, rightDestroyed: Bool) {
        if !leftDestroyed && !rightDestroyed {
            tickS6CyanBurstGate(dt: dt, lX: leftX, lY: leftY, rX: rightX, rY: rightY, pX: playerX, pY: playerY)
            tickS6PinkColumnGate(dt: dt, lensX: lensX, lensY: lensY)
        } else if !leftDestroyed || !rightDestroyed {
            tickS6CyanStreamGate(dt: dt, leftLive: !leftDestroyed, lX: leftX, lY: leftY, rX: rightX, rY: rightY)
            tickS6PinkRingGate(dt: dt, lensX: lensX, lensY: lensY)
        } else { tickS6PinkSpiralGate(dt: dt, lensX: lensX, lensY: lensY) }
    }
    private func tickS6CyanBurstGate(dt: Float, lX: Float, lY: Float, rX: Float, rY: Float, pX: Float, pY: Float) {
        if s6BurstRemaining > 0 {
            s6BurstGap -= dt; if s6BurstGap > 0 { return }
            let ox = s6RailAlt == 0 ? lX : rX; let oy = s6RailAlt == 0 ? lY : rY
            fireS6AimedTriple(mx: ox, my: oy, pX: pX, pY: pY)
            s6BurstRemaining -= 1; s6BurstGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP)
            if s6BurstRemaining == 0 { s6RailAlt = s6RailAlt == 0 ? 1 : 0 }
            return
        }
        turretTimer -= dt; if turretTimer > 0 { return }
        turretTimer = scaledInterval(EnemyWeaponSystem.S6_RAIL_INTERVAL)
        s6BurstRemaining = EnemyWeaponSystem.S6_BURST_COUNT; s6BurstGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP)
    }
    private func tickS6PinkColumnGate(dt: Float, lensX: Float, lensY: Float) {
        if s6ColumnRemaining > 0 {
            s6ColumnGap -= dt; if s6ColumnGap > 0 { return }
            fireBullet(startX: lensX, startY: lensY, velX: 0, velY: scaledSpeed(EnemyWeaponSystem.S6_CORE_VY), flags: EnemyBullet.FLAG_PINK)
            s6ColumnRemaining -= 1; s6ColumnGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP); return
        }
        s6LaserTimer -= dt; if s6LaserTimer > 0 { return }
        s6LaserTimer = scaledInterval(EnemyWeaponSystem.S6_WAVE_INTERVAL)
        s6ColumnRemaining = EnemyWeaponSystem.S6_CORE_SHOTS; s6ColumnGap = scaledInterval(EnemyWeaponSystem.S6_BURST_GAP)
    }
    private func tickS6CyanStreamGate(dt: Float, leftLive: Bool, lX: Float, lY: Float, rX: Float, rY: Float) {
        turretTimer -= dt; if turretTimer > 0 { return }
        turretTimer = scaledInterval(EnemyWeaponSystem.S6_OVERCHARGE_INTERVAL)
        let ox = leftLive ? lX : rX; let oy = leftLive ? lY : rY
        fireBullet(startX: ox, startY: oy, velX: 0, velY: scaledSpeed(EnemyWeaponSystem.S6_STREAM_SPEED), flags: EnemyBullet.FLAG_CYAN)
    }
    private func tickS6PinkRingGate(dt: Float, lensX: Float, lensY: Float) {
        s6RingTimer -= dt; if s6RingTimer > 0 { return }
        s6RingTimer = scaledInterval(EnemyWeaponSystem.S6_RING_INTERVAL)
        let spd = scaledSpeed(EnemyWeaponSystem.S6_RING_SPEED)
        for i in 0..<EnemyWeaponSystem.S6_RING_COUNT { let a = Float(i)*EnemyWeaponSystem.S6_RING_STEP; fireBullet(startX: lensX, startY: lensY, velX: cosf(a)*spd, velY: sinf(a)*spd, flags: EnemyBullet.FLAG_PINK) }
    }
    private func tickS6PinkSpiralGate(dt: Float, lensX: Float, lensY: Float) {
        spiralAngle += EnemyWeaponSystem.S6_SPIRAL_SPIN * dt
        if spiralAngle > Float.pi*2 { spiralAngle -= Float.pi*2 }
        spiralGate -= dt; if spiralGate > 0 { return }
        spiralGate = scaledInterval(EnemyWeaponSystem.S6_SPIRAL_INTERVAL)
        let spd = scaledSpeed(EnemyWeaponSystem.S6_SPIRAL_SPEED)
        let angles = [spiralAngle, spiralAngle + EnemyWeaponSystem.S6_HELIX_A1,
                      spiralAngle + EnemyWeaponSystem.S6_HELIX_A2, spiralAngle + EnemyWeaponSystem.S6_HELIX_A3,
                      -spiralAngle, -spiralAngle + EnemyWeaponSystem.S6_HELIX_A1,
                      -spiralAngle + EnemyWeaponSystem.S6_HELIX_A2, -spiralAngle + EnemyWeaponSystem.S6_HELIX_A3]
        for a in angles { fireBullet(startX: lensX, startY: lensY, velX: cosf(a)*spd, velY: sinf(a)*spd, flags: EnemyBullet.FLAG_PINK) }
    }
    private func fireS6AimedTriple(mx: Float, my: Float, pX: Float, pY: Float) {
        let ang = atan2f(pY-my, pX-mx); let spd = scaledSpeed(EnemyWeaponSystem.S6_BURST_SPEED)
        fireBullet(startX: mx, startY: my, velX: cosf(ang)*spd, velY: sinf(ang)*spd, flags: EnemyBullet.FLAG_CYAN)
        fireBullet(startX: mx, startY: my, velX: cosf(ang-0.08)*spd, velY: sinf(ang-0.08)*spd, flags: EnemyBullet.FLAG_CYAN)
        fireBullet(startX: mx, startY: my, velX: cosf(ang+0.08)*spd, velY: sinf(ang+0.08)*spd, flags: EnemyBullet.FLAG_CYAN)
    }

    func updateStage7Boss(dt: Float, cX: Float, cY: Float, bossW: Float, bossHalfH: Float,
                          pX: Float, pY: Float, leftHowitzerDead: Bool, rightHowitzerDead: Bool, blizzardDead: Bool) {
        let bossH = bossHalfH * 2
        if !leftHowitzerDead || !rightHowitzerDead {
            s7HowitzerTimer -= dt
            if s7HowitzerTimer <= 0 {
                s7HowitzerTimer = scaledInterval(EnemyWeaponSystem.S7_HOWITZER_INTERVAL)
                let fireLeft = s7HowitzerLeft; s7HowitzerLeft = !s7HowitzerLeft
                if fireLeft && !leftHowitzerDead {
                    fireS7Aimed(ox: cX + EnemyWeaponSystem.S7_LEFT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S7_LEFT_MUZZLE_Y*bossH, tX: pX, tY: pY)
                } else if !fireLeft && !rightHowitzerDead {
                    fireS7Aimed(ox: cX + EnemyWeaponSystem.S7_RIGHT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S7_RIGHT_MUZZLE_Y*bossH, tX: pX, tY: pY)
                } else if !leftHowitzerDead {
                    fireS7Aimed(ox: cX + EnemyWeaponSystem.S7_LEFT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S7_LEFT_MUZZLE_Y*bossH, tX: pX, tY: pY)
                } else {
                    fireS7Aimed(ox: cX + EnemyWeaponSystem.S7_RIGHT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S7_RIGHT_MUZZLE_Y*bossH, tX: pX, tY: pY)
                }
            }
        }
        if blizzardDead { return }
        s7BlizzardTimer -= dt; if s7BlizzardTimer > 0 { return }
        s7BlizzardTimer = scaledInterval(EnemyWeaponSystem.S7_BLIZZARD_INTERVAL)
        let spd = scaledSpeed(EnemyWeaponSystem.S7_BLIZZARD_SPEED)
        let sx = cX + EnemyWeaponSystem.S7_CHIN_MUZZLE_X*bossW; let sy = cY + EnemyWeaponSystem.S7_CHIN_MUZZLE_Y*bossH
        for i in -3...3 { let a = EnemyWeaponSystem.S2_DOWN_ANGLE + Float(i)*EnemyWeaponSystem.S7_BLIZZARD_STEP; fireBullet(startX: sx, startY: sy, velX: cosf(a)*spd, velY: sinf(a)*spd) }
    }
    private func fireS7Aimed(ox: Float, oy: Float, tX: Float, tY: Float) {
        let dx = tX-ox; let dy = tY-oy; let lenSq = dx*dx+dy*dy
        if lenSq < 0.0001 { return }
        let inv = scaledSpeed(EnemyWeaponSystem.S7_HOWITZER_SPEED) / sqrtf(lenSq)
        fireBullet(startX: ox, startY: oy, velX: dx*inv, velY: dy*inv)
    }

    func updateStage8Boss(dt: Float, cX: Float, cY: Float, bossW: Float, bossHalfH: Float,
                          pX: Float, pY: Float, leftGunDead: Bool, rightGunDead: Bool, aaDead: Bool) {
        let bossH = bossHalfH * 2
        if !leftGunDead || !rightGunDead {
            s8CoastalTimer -= dt
            if s8CoastalTimer <= 0 {
                s8CoastalTimer = scaledInterval(EnemyWeaponSystem.S8_COASTAL_INTERVAL)
                let fl = s8CoastalLeft; s8CoastalLeft = !s8CoastalLeft
                if fl && !leftGunDead { fireS8Aimed(ox: cX + EnemyWeaponSystem.S8_LEFT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S8_LEFT_MUZZLE_Y*bossH, tX: pX, tY: pY) }
                else if !fl && !rightGunDead { fireS8Aimed(ox: cX + EnemyWeaponSystem.S8_RIGHT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S8_RIGHT_MUZZLE_Y*bossH, tX: pX, tY: pY) }
                else if !leftGunDead  { fireS8Aimed(ox: cX + EnemyWeaponSystem.S8_LEFT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S8_LEFT_MUZZLE_Y*bossH, tX: pX, tY: pY) }
                else                  { fireS8Aimed(ox: cX + EnemyWeaponSystem.S8_RIGHT_MUZZLE_X*bossW, oy: cY + EnemyWeaponSystem.S8_RIGHT_MUZZLE_Y*bossH, tX: pX, tY: pY) }
            }
        }
        if aaDead { return }
        s8AaTimer -= dt; if s8AaTimer > 0 { return }
        s8AaTimer = scaledInterval(EnemyWeaponSystem.S8_AA_INTERVAL)
        let spd = scaledSpeed(EnemyWeaponSystem.S8_AA_SPEED)
        fireS8AaBurst(ox: cX + EnemyWeaponSystem.S8_AA_LEFT_X*bossW, oy: cY + EnemyWeaponSystem.S8_AA_LEFT_Y*bossH, spd: spd)
        fireS8AaBurst(ox: cX + EnemyWeaponSystem.S8_AA_RIGHT_X*bossW, oy: cY + EnemyWeaponSystem.S8_AA_RIGHT_Y*bossH, spd: spd)
    }
    private func fireS8Aimed(ox: Float, oy: Float, tX: Float, tY: Float) {
        let dx = tX-ox; let dy = tY-oy; let lenSq = dx*dx+dy*dy
        if lenSq < 0.0001 { return }
        let inv = scaledSpeed(EnemyWeaponSystem.S8_COASTAL_SPEED) / sqrtf(lenSq)
        fireBullet(startX: ox, startY: oy, velX: dx*inv, velY: dy*inv)
    }
    private func fireS8AaBurst(ox: Float, oy: Float, spd: Float) {
        for i in -1...1 { let a = EnemyWeaponSystem.S2_DOWN_ANGLE + Float(i)*EnemyWeaponSystem.S8_AA_STEP; fireBullet(startX: ox, startY: oy, velX: cosf(a)*spd, velY: sinf(a)*spd) }
    }

    // MARK: - General update

    func update(dt: Float) {
        let w = screenW; let h = screenH
        let sceneH = scene.map { Float($0.size.height) } ?? h
        for (i, b) in pool.enumerated() {
            if b.isActive {
                b.x += b.vx * dt; b.y += b.vy * dt
                let hw: Float = (b.flags & EnemyBullet.FLAG_LASER) != 0 ? EnemyWeaponSystem.S6_LASER_HW : EnemyWeaponSystem.HALF_BULLET_WIDTH
                let hh: Float = (b.flags & EnemyBullet.FLAG_LASER) != 0 ? EnemyWeaponSystem.S6_LASER_HH : EnemyWeaponSystem.HALF_BULLET_HEIGHT
                if b.x+hw < 0 || b.x-hw > w || b.y+hh < 0 || b.y-hh > h { b.isActive = false; b.flags = 0 }
            }
            let n = bulletNodes.count > i ? bulletNodes[i] : nil
            if let n = n {
                if b.isActive {
                    n.isHidden = false
                    n.position = CGPoint(x: CGFloat(b.x), y: CGFloat(sceneH - b.y))
                    let glow = n.childNode(withName: "glow") as? SKShapeNode
                    if (b.flags & EnemyBullet.FLAG_LASER) != 0 {
                        n.fillColor = UIColor(red: 0.88, green: 0.25, blue: 0.98, alpha: 1)
                        glow?.isHidden = true
                    } else if (b.flags & EnemyBullet.FLAG_PINK) != 0 {
                        n.fillColor = UIColor(red: 1, green: 0.31, blue: 0.78, alpha: 1)
                        glow?.isHidden = false
                    } else if (b.flags & EnemyBullet.FLAG_CYAN) != 0 {
                        n.fillColor = UIColor(red: 0.09, green: 0.94, blue: 1, alpha: 1)
                        glow?.isHidden = false
                    } else {
                        n.fillColor = UIColor(red: 0, green: 1, blue: 0.4, alpha: 1)
                        glow?.isHidden = false
                    }
                } else { n.isHidden = true }
            }
        }
        updateDeathClears(dt: dt)
    }

    private func updateDeathClears(dt: Float) {
        for i in 0..<EnemyWeaponSystem.CLEAR_SLOTS {
            if clearT[i] > 0 {
                clearT[i] -= dt
                let age = EnemyWeaponSystem.CLEAR_LIFE - clearT[i]
                let u = min(max(age / EnemyWeaponSystem.CLEAR_LIFE, 0), 1)
                let rSq = (EnemyWeaponSystem.CLEAR_RADIUS * u) * (EnemyWeaponSystem.CLEAR_RADIUS * u)
                let ox = clearX[i]; let oy = clearY[i]
                for b in pool where b.isActive {
                    let dx = b.x-ox; let dy = b.y-oy
                    if dx*dx + dy*dy <= rSq { b.isActive = false; b.flags = 0 }
                }
                if clearT[i] < 0 { clearT[i] = 0 }
            }
        }
    }

    // MARK: - Helpers
    private func scaledSpeed(_ base: Float) -> Float {
        (StageData.liveInstance?.shotSpeedScale() ?? 1) * base
    }
    private func scaledInterval(_ base: Float) -> Float {
        let div = StageData.liveInstance?.fireIntervalDivider() ?? 1
        return div < 0.01 ? base : base / div
    }
}
