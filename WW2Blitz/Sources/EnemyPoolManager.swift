import SpriteKit

class EnemyPoolManager {
    static let POOL_SIZE   = 48
    static let TYPE_COUNT  = 4
    static let TYPE_DRONE       = 0
    static let TYPE_KAMIKAZE    = 1
    static let TYPE_INTERCEPTOR = 2
    static let TYPE_HEAVY       = 3
    static let PATTERN_V_HOLD          = 1
    static let PATTERN_WEAVE           = 2
    static let PATTERN_DIAGONAL_SWEEP  = 3
    static let HOLD_Y_FRAC: Float         = 0.30
    static let HOLD_SEC: Float            = 1.15
    static let HEAVY_HOLD_Y_FRAC: Float   = 0.25
    static let HEAVY_HOLD_SEC: Float      = 5
    static let HEAVY_RETREAT_VY: Float    = -160
    static let S3_AIR_HEAVY_HOLD_Y_FRAC: Float = 0.16
    static let S3_AIR_HEAVY_HOLD_SEC: Float    = 2.2
    static let S3_AIR_HEAVY_RETREAT_VY: Float  = -280
    static let DESTROYER_HOLD_Y_FRAC: Float = 0.50
    static let DESTROYER_HOLD_SEC: Float    = 4
    static let DESTROYER_RETREAT_VY: Float  = 240
    static let HOLD_FIRE_GAP: Float   = 0.55
    static let INTERCEPT_REFIRE: Float = 0.85
    static let HEAVY_FIRE_GAP: Float   = 1.5
    static let MID_FIRE_GAP: Float     = 0.62
    static let MID_HOLD_SEC: Float     = 22
    static let MID_HOLD_Y_FRAC: Float  = 0.28
    static let MID_DESTROYER_HOLD_Y_FRAC: Float = 0.46
    static let MID_RETREAT_VY: Float   = 620
    static let MID_DRAW_SCALE: Float   = 1.55
    static let BURST_GAP: Float        = 0.10
    static let SCOUT_REFIRE: Float     = 0.85
    static let RING_COUNT = 8
    static let RING_SPEED: Float = 340
    static let SPREAD_RAD: Float  = Float(15.0 * Double.pi / 180)
    static let DIVE_VY: Float     = 280
    static let DIVE_ACCEL: Float  = 520
    static let WEAVE_RATE: Float  = 6.2
    static let WEAVE_AMP_FRAC: Float = 0.055
    static let WIDTH_FRAC: [Float] = [0.18, 0.14, 0.22, 0.28]
    static let GROUND_DRAW_SCALE: Float = 1.48
    static let FIRE_DELAY_MIN: Float = 0.5
    static let FIRE_DELAY_MAX: Float = 1.5
    static let AIMED_SHOT_SPEED: Float = 550
    static let SPLINTER_ACCEL: Float   = 180
    static let SWEEP_ARC_DURATION: Float  = 4.8
    static let SWEEP_ARC_SPACING: Float   = 1.15
    static let SWEEP_ARC_DIP_FRAC: Float  = 0.30
    static let SWEEP_ARC_START_Y_FRAC: Float = 0.08
    static let SWEEP_ARC_MARGIN: Float    = 64
    static let SWEEP_LUT = 64

    private(set) var pool: [Enemy]
    private var screenW: Float = 0
    private var screenH: Float = 0
    private var halfW = [Float](repeating: 0, count: TYPE_COUNT)
    private var halfH = [Float](repeating: 0, count: TYPE_COUNT)
    private var sweepArcS = [Float](repeating: 0, count: EnemyPoolManager.SWEEP_LUT)
    private var sweepArcLen: Float = 1
    private var sweepTailDelay: Float = 0.75
    private var rng: UInt32 = 2463534242
    private var lastPlayerX: Float = 0; private var lastPlayerY: Float = 0
    private var playerVelX: Float = 0; private var playerVelY: Float = 0
    private var hasPlayerSample: Bool = false

    // SpriteKit
    private weak var scene: SKScene?
    private var enemyNodes: [SKSpriteNode] = []
    private var textures: [String: SKTexture] = [:]
    private var skinTankTex: SKTexture? = nil
    private var skinDestroyerTex: SKTexture? = nil
    private var skinWagonTex: SKTexture? = nil
    private var skinHelicopterTex: SKTexture? = nil
    private var droneRedTex: SKTexture? = nil

    init() {
        pool = (0..<EnemyPoolManager.POOL_SIZE).map { _ in Enemy() }
    }

    func setup(scene: SKScene) {
        self.scene = scene
        screenW = Float(scene.size.width); screenH = Float(scene.size.height)
        let typeNames = ["enemy_drone","enemy_kamikaze","enemy_interceptor","enemy_heavy"]
        for name in typeNames { textures[name] = GameArt.texture("Images/\(name)") }
        droneRedTex = GameArt.texture("Images/enemy_drone_red")
        // Create node pool
        for _ in 0..<EnemyPoolManager.POOL_SIZE {
            let n = SKSpriteNode()
            n.zPosition = 35; n.isHidden = true
            scene.addChild(n); enemyNodes.append(n)
            ArcadeOutline.attach(to: n)
        }
        computeHalfSizes()
        rebuildSweepLut()
    }

    func onSizeChanged(width: Int, height: Int) {
        screenW = Float(width); screenH = Float(height)
        computeHalfSizes()
        rebuildSweepLut()
    }

    private func computeHalfSizes() {
        guard screenW > 0 else { return }
        let typeNames = ["enemy_drone","enemy_kamikaze","enemy_interceptor","enemy_heavy"]
        for t in 0..<EnemyPoolManager.TYPE_COUNT {
            guard let tex = textures[typeNames[t]] else { continue }
            let tw = Float(scene!.size.width) * EnemyPoolManager.WIDTH_FRAC[t]
            let aspect = Float(tex.size().height / tex.size().width)
            let th = tw * aspect
            halfW[t] = tw * 0.5; halfH[t] = th * 0.5
        }
    }

    func bindTheaterSkins(tank: SKTexture?, destroyer: SKTexture?, wagon: SKTexture?, helicopter: SKTexture?) {
        skinTankTex = tank; skinDestroyerTex = destroyer; skinWagonTex = wagon; skinHelicopterTex = helicopter
    }

    func sweepArcTailDelay() -> Float { sweepTailDelay }
    func getEnemyPool() -> [Enemy] { pool }
    func getPoolSize() -> Int { EnemyPoolManager.POOL_SIZE }
    func halfWOf(_ type: Int) -> Float { halfW[typeIndex(type)] }
    func halfHOf(_ type: Int) -> Float { halfH[typeIndex(type)] }
    func halfWOf(_ e: Enemy) -> Float { halfWOf(e.type) * drawScale(e) }
    func halfHOf(_ e: Enemy) -> Float { halfHOf(e.type) * drawScale(e) }
    private func drawScale(_ e: Enemy) -> Float {
        if e.isMidBoss { return EnemyPoolManager.MID_DRAW_SCALE }
        if e.isLandVehicle || e.isWagon { return EnemyPoolManager.GROUND_DRAW_SCALE }
        return 1
    }
    private func typeIndex(_ t: Int) -> Int { t >= 0 && t < EnemyPoolManager.TYPE_COUNT ? t : 0 }

    func countActive() -> Int { pool.filter { $0.isActive }.count }

    func deactivateAll() {
        for e in pool {
            e.isActive = false; e.isRedShipAnchor = false
            e.isDestroyer = false; e.isLandVehicle = false; e.isWagon = false
            e.isHelicopter = false; e.isMidBoss = false
            e.flightProfile = 0; e.flightTime = 0; e.patternDelay = 0
            e.deathClearBullets = false; e.diamondLeader = false; e.diamondWingSign = 0
            e.splinterVeer = false; e.shudderTimer = 0
        }
        enemyNodes.forEach { $0.isHidden = true }
        hasPlayerSample = false; playerVelX = 0; playerVelY = 0
    }

    func spawnEnemy(startX: Float, startY: Float, velocityX: Float, velocityY: Float,
                    enemyType: Int, pattern: Int = 0, health: Int = 1,
                    isRedShipAnchor: Bool = false, flightProfile: Int = 0,
                    patternDelay: Float = 0, spawnCue: Int = 0,
                    isDestroyer: Bool = false, isLandVehicle: Bool = false, isWagon: Bool = false,
                    isHelicopter: Bool = false, isMidBoss: Bool = false) {
        for e in pool where !e.isActive {
            e.x = startX; e.y = startY; e.vx = velocityX; e.vy = velocityY
            e.type = enemyType; e.pattern = pattern; e.flightProfile = flightProfile
            e.flightTime = 0; e.patternDelay = patternDelay
            e.aiPhase = 0; e.holdTimer = 0; e.weaveT = 0; e.homeX = startX
            e.health = max(1, health); e.fireTimer = scaledFireDelay()
            e.burstLeft = 0; e.burstWait = 0; e.aimVx = 0; e.aimVy = 0
            e.isRedShipAnchor = isRedShipAnchor
            e.isDestroyer = isDestroyer; e.isLandVehicle = isLandVehicle; e.isWagon = isWagon
            e.isHelicopter = isHelicopter; e.isMidBoss = isMidBoss
            e.deathClearBullets = spawnCue == SpawnEvent.CUE_DEATH_CLEAR
            e.diamondLeader     = spawnCue == SpawnEvent.CUE_DIAMOND_LEADER
            e.diamondWingSign   = spawnCue == SpawnEvent.CUE_DIAMOND_WING_L ? -1 :
                                  spawnCue == SpawnEvent.CUE_DIAMOND_WING_R ?  1 : 0
            e.splinterVeer = false; e.shudderTimer = 0; e.isActive = true
            return
        }
    }

    func triggerDiamondSplinter() {
        for e in pool where e.isActive && e.diamondWingSign != 0 { e.splinterVeer = true }
    }

    func hasActiveRedShipAnchor() -> Bool { pool.contains { $0.isActive && $0.isRedShipAnchor } }

    func hasActiveMidBoss() -> Bool { pool.contains { $0.isActive && $0.isMidBoss } }

    func beginMidBossExit() {
        for e in pool where e.isActive && e.isMidBoss {
            e.aiPhase = 2
            e.vx = 0
            e.vy = EnemyPoolManager.MID_RETREAT_VY
        }
    }

    func update(dt: Float, playerX: Float, playerY: Float, weapons: EnemyWeaponSystem) {
        let speed = EnemyPoolManager.AIMED_SHOT_SPEED * (StageData.liveInstance?.shotSpeedScale() ?? 1)
        if dt > 0.0001 && hasPlayerSample {
            playerVelX = (playerX - lastPlayerX) / dt
            playerVelY = (playerY - lastPlayerY) / dt
        }
        lastPlayerX = playerX; lastPlayerY = playerY; hasPlayerSample = true
        let sceneH = scene.map { Float($0.size.height) } ?? screenH
        for (i, e) in pool.enumerated() {
            guard e.isActive else { updateNode(enemyNodes[i], active: false, e: e, sceneH: sceneH); continue }
            if e.shudderTimer > 0 { e.shudderTimer -= dt }
            if e.flightProfile == Enemy.FLIGHT_PROFILE_SWEEP_ARC {
                updateSweepArc(e, dt: dt); updateNode(enemyNodes[i], active: true, e: e, sceneH: sceneH); continue
            }
            if e.type == EnemyPoolManager.TYPE_KAMIKAZE && (StageData.liveInstance?.kamikazeSeeks() ?? false) {
                e.steerToward(targetX: playerX, targetY: playerY, dt: dt, turnRate: Enemy.KAMI_TURN_RATE)
            }
            switch e.pattern {
            case EnemyPoolManager.PATTERN_V_HOLD:
                updateInterceptorHold(e, dt: dt)
            case EnemyPoolManager.PATTERN_WEAVE:
                e.weaveT += dt
                e.x = e.homeX + sinf(e.weaveT * EnemyPoolManager.WEAVE_RATE) * (screenW * EnemyPoolManager.WEAVE_AMP_FRAC)
                e.y += e.vy * dt
            default:
                if e.splinterVeer { e.vx += e.diamondWingSign * EnemyPoolManager.SPLINTER_ACCEL * dt }
                e.x += e.vx * dt; e.y += e.vy * dt
            }
            let eh = halfHOf(e); let ew = halfWOf(e)
            if e.y - eh > screenH || e.x - ew > screenW || (e.x + ew < 0 && e.vx <= 0) || (e.y + eh < 0 && e.vy <= 0) {
                recycleEnemy(e); updateNode(enemyNodes[i], active: false, e: e, sceneH: sceneH); continue
            }
            if e.type != EnemyPoolManager.TYPE_KAMIKAZE {
                updateEnemyFire(e, dt: dt, playerX: playerX, playerY: playerY, weapons: weapons, speed: speed)
            }
            updateNode(enemyNodes[i], active: true, e: e, sceneH: sceneH)
        }
    }

    private func updateNode(_ node: SKSpriteNode, active: Bool, e: Enemy, sceneH: Float) {
        if !active { node.isHidden = true; return }
        node.isHidden = false
        let tex = texureFor(e)
        if node.texture !== tex { node.texture = tex }
        let hw = CGFloat(halfWOf(e)); let hh = CGFloat(halfHOf(e))
        node.size = CGSize(width: hw*2, height: hh*2)
        var dx: Float = 0
        if e.type == EnemyPoolManager.TYPE_HEAVY && e.shudderTimer > 0 {
            dx = Int(e.shudderTimer * 100) % 2 == 0 ? Enemy.SHUDDER_AMPLITUDE : -Enemy.SHUDDER_AMPLITUDE
        }
        node.position = CGPoint(x: CGFloat(e.x + dx), y: CGFloat(sceneH - e.y))
        node.zRotation = .pi  // Enemies drawn rotated 180° (facing down in Android) = face up in SpriteKit
        node.zPosition = e.isGroundHeavy ? 32 : 35
        ArcadeOutline.sync(node)
    }

    private func texureFor(_ e: Enemy) -> SKTexture? {
        if e.isDestroyer    { return skinDestroyerTex ?? textures["enemy_heavy"] }
        if e.isLandVehicle  { return skinTankTex       ?? textures["enemy_heavy"] }
        if e.isWagon        { return skinWagonTex       ?? textures["enemy_heavy"] }
        if e.isHelicopter   { return skinHelicopterTex ?? textures["enemy_heavy"] }
        if e.isRedShipAnchor { return droneRedTex       ?? textures["enemy_drone"] }
        let names = ["enemy_drone","enemy_kamikaze","enemy_interceptor","enemy_heavy"]
        let t = typeIndex(e.type)
        return textures[names[t]] ?? textures["enemy_drone"]
    }

    private func recycleEnemy(_ e: Enemy) {
        e.isActive = false; e.isRedShipAnchor = false; e.isDestroyer = false
        e.isLandVehicle = false; e.isWagon = false; e.isHelicopter = false; e.isMidBoss = false
        e.flightProfile = 0; e.flightTime = 0
        e.patternDelay = 0; e.deathClearBullets = false; e.diamondLeader = false
        e.diamondWingSign = 0; e.splinterVeer = false
    }

    private func updateSweepArc(_ e: Enemy, dt: Float) {
        e.patternDelay -= dt
        if e.patternDelay > 0 {
            e.x = -EnemyPoolManager.SWEEP_ARC_MARGIN - halfWOf(e.type)
            e.y = screenH * EnemyPoolManager.SWEEP_ARC_START_Y_FRAC; return
        }
        e.flightTime += dt
        let t = e.flightTime / EnemyPoolManager.SWEEP_ARC_DURATION
        if t >= 1 { recycleEnemy(e); return }
        let u = sweepUForArcLength(t * sweepArcLen)
        let x0 = -EnemyPoolManager.SWEEP_ARC_MARGIN
        let x1 = screenW + EnemyPoolManager.SWEEP_ARC_MARGIN
        let y0 = screenH * EnemyPoolManager.SWEEP_ARC_START_Y_FRAC
        e.x = x0 + (x1 - x0) * u
        e.y = y0 + screenH * EnemyPoolManager.SWEEP_ARC_DIP_FRAC * sinf(u * Enemy.PI)
    }

    private func rebuildSweepLut() {
        let n = EnemyPoolManager.SWEEP_LUT
        let x0 = -EnemyPoolManager.SWEEP_ARC_MARGIN
        let x1 = screenW + EnemyPoolManager.SWEEP_ARC_MARGIN
        let y0 = screenH * EnemyPoolManager.SWEEP_ARC_START_Y_FRAC
        let dip = screenH * EnemyPoolManager.SWEEP_ARC_DIP_FRAC
        let span = x1 - x0
        var prevX = x0; var prevY = y0
        sweepArcS[0] = 0
        for i in 1..<n {
            let u = Float(i) / Float(n-1)
            let x = x0 + span * u; let y = y0 + dip * sinf(u * Enemy.PI)
            let dx = x - prevX; let dy = y - prevY
            sweepArcS[i] = sweepArcS[i-1] + sqrtf(dx*dx + dy*dy)
            prevX = x; prevY = y
        }
        sweepArcLen = max(1, sweepArcS[n-1])
        let shipW = halfW[EnemyPoolManager.TYPE_DRONE] * 2
        let shipH = halfH[EnemyPoolManager.TYPE_DRONE] * 2
        let shipSpan = max(shipW, shipH)
        let gap = shipSpan > 1 ? shipSpan * EnemyPoolManager.SWEEP_ARC_SPACING : sweepArcLen * 0.12
        sweepTailDelay = (gap / sweepArcLen) * EnemyPoolManager.SWEEP_ARC_DURATION
    }

    private func sweepUForArcLength(_ s: Float) -> Float {
        let n = EnemyPoolManager.SWEEP_LUT; let last = n - 1
        if s <= 0 { return 0 }; if s >= sweepArcS[last] { return 1 }
        var lo = 0; var hi = last
        while lo < hi { let mid = (lo+hi) >> 1; if sweepArcS[mid] < s { lo = mid+1 } else { hi = mid } }
        let i = lo; if i <= 0 { return 0 }
        let s0 = sweepArcS[i-1]; let s1 = sweepArcS[i]; let ds = s1-s0
        let f: Float = ds > 0.0001 ? (s-s0)/ds : 0
        return Float(i-1)/Float(last) + f/Float(last)
    }

    private func updateInterceptorHold(_ e: Enemy, dt: Float) {
        let heavyHold = e.type == EnemyPoolManager.TYPE_HEAVY
        let s3AirHeavy = heavyHold && !e.isGroundHeavy && (StageData.liveInstance?.def.airHeavyHighHold ?? false)
        let holdY = screenH * (
            e.isMidBoss && e.isGroundHeavy ? EnemyPoolManager.MID_DESTROYER_HOLD_Y_FRAC
            : e.isMidBoss ? EnemyPoolManager.MID_HOLD_Y_FRAC
            : e.isGroundHeavy ? EnemyPoolManager.DESTROYER_HOLD_Y_FRAC
            : s3AirHeavy ? EnemyPoolManager.S3_AIR_HEAVY_HOLD_Y_FRAC
            : heavyHold ? EnemyPoolManager.HEAVY_HOLD_Y_FRAC
            : EnemyPoolManager.HOLD_Y_FRAC)
        switch e.aiPhase {
        case 0:
            e.x += e.vx * dt; e.y += e.vy * dt
            if e.y >= holdY {
                e.y = holdY; e.vx = 0; e.vy = 0; e.aiPhase = 1; e.fireTimer = 0
                e.holdTimer = e.isMidBoss ? EnemyPoolManager.MID_HOLD_SEC
                              : e.isGroundHeavy ? EnemyPoolManager.DESTROYER_HOLD_SEC
                              : s3AirHeavy    ? EnemyPoolManager.S3_AIR_HEAVY_HOLD_SEC
                              : heavyHold     ? EnemyPoolManager.HEAVY_HOLD_SEC
                              : EnemyPoolManager.HOLD_SEC
            }
        case 1:
            e.holdTimer -= dt
            if e.holdTimer <= 0 {
                e.aiPhase = 2
                e.vy = e.isMidBoss ? EnemyPoolManager.MID_RETREAT_VY
                       : e.isGroundHeavy ? EnemyPoolManager.DESTROYER_RETREAT_VY
                       : s3AirHeavy    ? EnemyPoolManager.S3_AIR_HEAVY_RETREAT_VY
                       : heavyHold     ? EnemyPoolManager.HEAVY_RETREAT_VY
                       : EnemyPoolManager.DIVE_VY
            }
        default:
            if !heavyHold { e.vy += EnemyPoolManager.DIVE_ACCEL * dt }
            e.y += e.vy * dt
        }
    }

    private func updateEnemyFire(_ e: Enemy, dt: Float, playerX: Float, playerY: Float,
                                  weapons: EnemyWeaponSystem, speed: Float) {
        if e.burstLeft > 0 {
            e.burstWait -= dt
            if e.burstWait <= 0 {
                writeSniperAim(e, playerX: playerX, playerY: playerY, speed: speed)
                weapons.fireBullet(startX: e.x, startY: e.y, velX: e.aimVx, velY: e.aimVy)
                SoundManager.instance.playSFX(SoundManager.SFX_LASER)
                e.burstLeft -= 1
                if e.burstLeft > 0 { e.burstWait = EnemyPoolManager.BURST_GAP }
                else { e.fireTimer = scaledInterval(EnemyPoolManager.SCOUT_REFIRE) }
            }
            return
        }
        e.fireTimer -= dt; if e.fireTimer > 0 { return }
        switch e.type {
        case EnemyPoolManager.TYPE_HEAVY:
            if e.isMidBoss {
                if e.aiPhase == 1 {
                    fireMidBoss(e, weapons: weapons, speed: EnemyPoolManager.RING_SPEED * (StageData.liveInstance?.shotSpeedScale() ?? 1))
                }
                e.fireTimer = scaledInterval(EnemyPoolManager.MID_FIRE_GAP)
            } else {
                fireHeavyRing(e, weapons: weapons, speed: EnemyPoolManager.RING_SPEED * (StageData.liveInstance?.shotSpeedScale() ?? 1))
                e.fireTimer = scaledInterval(EnemyPoolManager.HEAVY_FIRE_GAP)
            }
        case EnemyPoolManager.TYPE_INTERCEPTOR:
            writeSniperAim(e, playerX: playerX, playerY: playerY, speed: speed)
            fireInterceptorSpread(e, weapons: weapons, speed: speed)
            let gap = e.pattern == EnemyPoolManager.PATTERN_V_HOLD && e.aiPhase == 1 ? EnemyPoolManager.HOLD_FIRE_GAP : EnemyPoolManager.INTERCEPT_REFIRE
            e.fireTimer = scaledInterval(gap)
        default:
            if writeSniperAim(e, playerX: playerX, playerY: playerY, speed: speed) {
                weapons.fireBullet(startX: e.x, startY: e.y, velX: e.aimVx, velY: e.aimVy)
                SoundManager.instance.playSFX(SoundManager.SFX_LASER)
                e.burstLeft = 2; e.burstWait = EnemyPoolManager.BURST_GAP
            } else { e.fireTimer = scaledInterval(EnemyPoolManager.SCOUT_REFIRE) }
        }
    }

    @discardableResult
    private func writeSniperAim(_ e: Enemy, playerX: Float, playerY: Float, speed: Float) -> Bool {
        let s = StageData.liveInstance
        let slopMag = s?.aimSlopRad() ?? 0
        let slop: Float = slopMag > 0 ? (nextUnit() * 2 - 1) * slopMag : 0
        return e.writeAimedShot(targetX: playerX, targetY: playerY,
                                 playerVelX: playerVelX, playerVelY: playerVelY,
                                 shotSpeed: speed, applyLead: s?.shouldLeadShots() ?? false,
                                 slopRad: slop)
    }

    private func fireInterceptorSpread(_ e: Enemy, weapons: EnemyWeaponSystem, speed: Float) {
        let span = max(0, 1 + (StageData.liveInstance?.burstBonus() ?? 0))
        let lenSq = e.aimVx*e.aimVx + e.aimVy*e.aimVy
        let baseAng: Float = lenSq > 0.0001 ? atan2f(e.aimVy, e.aimVx) : Float.pi * 0.5
        for k in -span...span {
            let fa = baseAng + Float(k) * EnemyPoolManager.SPREAD_RAD
            weapons.fireBullet(startX: e.x, startY: e.y, velX: cosf(fa)*speed, velY: sinf(fa)*speed)
        }
        SoundManager.instance.playSFX(SoundManager.SFX_LASER)
    }

    private func fireMidBoss(_ e: Enemy, weapons: EnemyWeaponSystem, speed: Float) {
        if !writeSniperAim(e, playerX: lastPlayerX, playerY: lastPlayerY, speed: speed) { return }
        weapons.fireBullet(startX: e.x, startY: e.y, velX: e.aimVx, velY: e.aimVy)
        let base = atan2f(e.aimVy, e.aimVx)
        let fan: Float = 0.32
        weapons.fireBullet(startX: e.x, startY: e.y, velX: cosf(base - fan) * speed, velY: sinf(base - fan) * speed)
        weapons.fireBullet(startX: e.x, startY: e.y, velX: cosf(base + fan) * speed, velY: sinf(base + fan) * speed)
        let down = speed * 0.82
        let side = speed * 0.38
        weapons.fireBullet(startX: e.x, startY: e.y, velX: -side, velY: down)
        weapons.fireBullet(startX: e.x, startY: e.y, velX:  side, velY: down)
        SoundManager.instance.playSFX(SoundManager.SFX_LASER)
    }

    private func fireHeavyRing(_ e: Enemy, weapons: EnemyWeaponSystem, speed: Float) {
        let count = max(1, 12 + (StageData.liveInstance?.burstBonus() ?? 0))
        let step = Float.pi * 2 / Float(count)
        for k in 0..<count {
            let ang = Float(k) * step
            weapons.fireBullet(startX: e.x, startY: e.y, velX: cosf(ang)*speed, velY: sinf(ang)*speed)
        }
        SoundManager.instance.playSFX(SoundManager.SFX_LASER)
    }

    private func scaledInterval(_ base: Float) -> Float {
        let div = StageData.liveInstance?.fireIntervalDivider() ?? 1
        return div < 0.01 ? base : base / div
    }
    private func scaledFireDelay() -> Float {
        let raw = EnemyPoolManager.FIRE_DELAY_MIN + nextUnit() * (EnemyPoolManager.FIRE_DELAY_MAX - EnemyPoolManager.FIRE_DELAY_MIN)
        return scaledInterval(raw)
    }
    private func nextUnit() -> Float {
        rng = rng &* 1664525 &+ 1013904223
        return Float((rng >> 8) & 0xFFFFFF) / 16777215.0
    }
}
