import SpriteKit

class BossController {
    // Part type constants
    static let TYPE_CORE         = 0
    static let TYPE_LEFT_FLANK   = 1
    static let TYPE_RIGHT_FLANK  = 2
    static let TYPE_LEFT_WING    = 1
    static let TYPE_RIGHT_WING   = 2
    static let TYPE_TURRET       = 3
    static let TYPE_STAGE2_LEFT_TREAD = 4
    static let TYPE_STAGE2_RIGHT_TREAD = 5
    static let TYPE_STAGE2_MAIN_TURRET = 6
    static let TYPE_STAGE3_LEFT_FLAK = 7
    static let TYPE_STAGE3_RIGHT_FLAK = 8
    static let TYPE_STAGE3_MEGA_CANNON = 9
    static let TYPE_STAGE4_LEFT_MORTAR = 10
    static let TYPE_STAGE4_RIGHT_MORTAR = 11
    static let TYPE_STAGE4_HEAVY_GATLING = 12
    static let TYPE_WINTER_LEFT_HOWITZER = 10
    static let TYPE_WINTER_RIGHT_HOWITZER = 11
    static let TYPE_WINTER_BLIZZARD = 12
    static let TYPE_ATOLL_LEFT_GUN = 10
    static let TYPE_ATOLL_RIGHT_GUN = 11
    static let TYPE_ATOLL_AA = 12
    static let FX_PHASE          = 1
    static let FX_DEATH          = 2
    static let FX_VICTORY_START  = 4
    static let FX_VICTORY_CASCADE = 8
    static let FX_VICTORY_SHATTER = 16
    static let MAX_PART_COUNT    = 14
    static let HOVER_Y_FRAC: Float = 0.25
    static let CORE_WIDTH_FRAC: Float = 0.85
    static let ENTER_SPEED: Float = 90
    static let SWEEP_RATE: Float  = 0.55
    static let SWEEP_AMP: Float   = 0.18
    static let S5_CORE_HP = 350; static let S5_FLANK_HP = 180
    static let S5_LEFT_L: Float = -0.50; static let S5_LEFT_R: Float = -0.18
    static let S5_RIGHT_L: Float = 0.18; static let S5_RIGHT_R: Float = 0.50
    static let S5_FLANK_T: Float = -0.35; static let S5_FLANK_B: Float = 0.35
    static let S5_CORE_L: Float = -0.18; static let S5_CORE_R: Float = 0.18
    static let S5_CORE_T: Float = -0.45; static let S5_CORE_B: Float = 0.48
    static let S6_CORE_HP = 380; static let S6_FLANK_HP = 190
    static let S6_LEFT_L: Float = -0.50; static let S6_LEFT_R: Float = -0.20
    static let S6_RIGHT_L: Float = 0.20; static let S6_RIGHT_R: Float = 0.50
    static let S6_FLANK_T: Float = -0.38; static let S6_FLANK_B: Float = 0.38
    static let S6_CORE_L: Float = -0.20; static let S6_CORE_R: Float = 0.20
    static let S6_CORE_T: Float = -0.48; static let S6_CORE_B: Float = 0.48
    static let S6_LEFT_MUZZLE_X: Float = -0.44; static let S6_LEFT_MUZZLE_Y: Float = 0.38
    static let S6_RIGHT_MUZZLE_X: Float = 0.44; static let S6_RIGHT_MUZZLE_Y: Float = 0.38
    static let S6_CORE_LENS_X: Float = 0; static let S6_CORE_LENS_Y: Float = -0.02
    static let S6_PHASE2_CLOCK: Float = 15.1; static let S6_PHASE3_CLOCK: Float = 35.1
    static let VICTORY_CASCADE_START: Float = 0.5
    static let VICTORY_SHATTER_AT: Float = 3.0
    static let VICTORY_END: Float = 4.5
    static let VICTORY_CASCADE_STEP: Float = 0.15
    static let VICTORY_CLUSTER = 8
    static let EXPLODE_FRAME_COUNT = 8
    static let EXPLODE_FRAME_SEC: Float = 0.13
    static let S1_CORE_HP = 240; static let S1_WING_HP = 70; static let S1_TURRET_HP = 58
    static let S2_CORE_HP = 330; static let S2_TREAD_HP = 100; static let S2_TURRET_HP = 88
    static let S3_CORE_HP = 480; static let S3_FLAK_HP = 125; static let S3_CANNON_HP = 190
    static let S4_CORE_HP = 520; static let S4_MORTAR_HP = 140; static let S4_GATLING_HP = 160
    static let S7_CORE_HP = 500; static let S7_HOWITZER_HP = 150; static let S7_BLIZZARD_HP = 170
    static let S8_CORE_HP = 480; static let S8_GUN_HP = 145; static let S8_AA_HP = 165
    static let DOWN_ANGLE: Float = 1.5707964
    static let S1_SWEEP_INTERVAL: Float = 0.16
    static let S1_SWEEP_SPEED: Float = 480
    static let S1_SWEEP_FREQ: Float = 3.5
    static let S1_SWEEP_AMP: Float = 0.6
    static let S1_SWEEP_ARC_STEP: Float = 0.12
    static let S2_RING_INTERVAL: Float = 0.80
    static let S2_RING_SPEED: Float = 340
    static let S2_RING_COUNT = 16
    static let S2_RING_STEP: Float = Float.pi * 2 / Float(S2_RING_COUNT)
    static let S2_SNIPER_INTERVAL: Float = 0.25
    static let S2_SNIPER_SPEED: Float = 600
    static let S2_SNIPER_SEP: Float = 8
    static let S3_SPIRAL_INTERVAL: Float = 0.10
    static let S3_SPIRAL_SPEED: Float = 440
    static let S3_SPIRAL_SPIN: Float = 5.2
    static let S3_SPIRAL_COUNT = 4
    static let S3_SPIRAL_STEP: Float = Float.pi * 2 / Float(S3_SPIRAL_COUNT)
    static let S4_SPIRAL_INTERVAL: Float = 0.12
    static let S4_SPIRAL_SPEED: Float = 310
    static let S4_SPIRAL_SPIN: Float = 4.5
    static let S4_SPIRAL_COUNT = 6
    static let S4_SPIRAL_STEP: Float = Float.pi * 2 / Float(S4_SPIRAL_COUNT)
    static let S7_RING_INTERVAL: Float = 0.20
    static let S7_RING_SPEED: Float = 280
    static let S7_RING_SPIN: Float = 2.8
    static let S7_RING_COUNT = 8
    static let S7_RING_STEP: Float = Float.pi * 2 / Float(S7_RING_COUNT)
    static let S8_FAN_INTERVAL: Float = 0.22
    static let S8_FAN_SPEED: Float = 300
    static let S8_FAN_STEP: Float = 0.2618

    private var parts = (0..<MAX_PART_COUNT).map { _ in BossComponent() }
    private var screenW: Float = 0; private var screenH: Float = 0
    private var coreX: Float = 0; private var coreY: Float = 0
    private var hoverY: Float = 0; private var sweepPhase: Float = 0
    private var entering = false; private var active = false
    private var exploding = false; private var explosionTimer: Float = 0
    private var activeExpFrame = 0; private var currentStage = 1
    private var combatKind: BossCombatKind = .plane; private var triPartBoss = false
    private var corePhaseOpen = false; private var visualFlags = 0
    private var bodyHalfW: Float = 0; private var bodyHalfH: Float = 0
    private var leftFlankBounds = CGRect.zero; private var rightFlankBounds = CGRect.zero
    private var coreBounds = CGRect.zero
    private var leftFlankShudder: Float = 0; private var rightFlankShudder: Float = 0; private var coreShudder: Float = 0
    private var s5CoreArmorBank: Float = 0; private var s5HitDestroyed = false
    private var s5HitDestroyX: Float = 0; private var s5HitDestroyY: Float = 0
    private var hasDroppedLeftReward = false; private var hasDroppedRightReward = false; private var hasDroppedCoreReward = false
    private var s5WeaponPower = 1; private var s5BombStock = 3
    private var victorySequenceTimer: Float = 0; private var victoryCascadeGate: Float = 0
    private var victoryShatterFired = false; private var s5ShowTerminalWreck = false
    private var victoryLcg: UInt64 = 2463534242
    private var s6SawOneFlankDown = false; private var s6SawBothFlanksDown = false
    private var partSfxPlayed = [Bool](repeating: false, count: MAX_PART_COUNT)
    private weak var stageTimeline: SpawnTimeline?
    private var s1SweepTimer: Float = 0
    private var s1SweepFireTimer: Float = 0
    private var s1SweepDirection: Float = 1
    private var s2DesperationTimer: Float = 0
    private var s2RingTimer: Float = 0
    private var s2SniperTimer: Float = 0
    private var s3DesperationAngle: Float = 0
    private var s3SpiralTimer: Float = 0
    private var s4SpiralTimer: Float = 0
    private var s4SpiralAngle: Float = 0
    private var s7RingTimer: Float = 0
    private var s7RingAngle: Float = 0
    private var s8FanTimer: Float = 0

    // SpriteKit
    private weak var scene: SKScene?
    private var bodyNode: SKSpriteNode?
    private var leftWreckNode: SKSpriteNode?
    private var rightWreckNode: SKSpriteNode?
    private var centerWreckNode: SKSpriteNode?
    private var leftWreckCrop: SKCropNode?
    private var rightWreckCrop: SKCropNode?
    private var bodyTex: SKTexture?
    private var leftWreckTex: SKTexture?
    private var rightWreckTex: SKTexture?
    private var centerWreckTex: SKTexture?
    private var expFrames: [SKTexture] = []

    func setup(scene: SKScene) {
        self.scene = scene
        expFrames = (1...BossController.EXPLODE_FRAME_COUNT).map { GameArt.texture("Images/boss_explode_f\($0)") }
        func sprite(_ z: CGFloat) -> SKSpriteNode {
            let n = SKSpriteNode(); n.zPosition = z; n.isHidden = true
            scene.addChild(n); return n
        }
        bodyNode = sprite(36)
        leftWreckNode = sprite(36.1)
        rightWreckNode = sprite(36.1)
        centerWreckNode = sprite(36.2)
        let lc = SKCropNode(); lc.zPosition = 36.1; lc.isHidden = true; scene.addChild(lc)
        let rc = SKCropNode(); rc.zPosition = 36.1; rc.isHidden = true; scene.addChild(rc)
        let ls = SKSpriteNode(); ls.name = "wreck"; lc.addChild(ls)
        let rs = SKSpriteNode(); rs.name = "wreck"; rc.addChild(rs)
        leftWreckCrop = lc
        rightWreckCrop = rc
    }

    func onSizeChanged(width: Int, height: Int) {
        screenW = Float(width); screenH = Float(height)
        hoverY = Float(height) * BossController.HOVER_Y_FRAC
        applyKit(stage: currentStage)
        loadSheet(stage: currentStage)
        layoutOffsets()
    }

    func bindStage(_ stage: Int) {
        applyKit(stage: stage)
        if screenW <= 0 { return }
        loadSheet(stage: currentStage); layoutOffsets()
    }

    private func applyKit(stage: Int) {
        currentStage = stage
        let def = StageCatalog.get(stage)
        combatKind = def.bossCombat; triPartBoss = def.boss.triPart
    }

    func beginEntranceForStage(_ stage: Int) {
        if screenW <= 0 { return }
        if currentStage != stage || bodyTex == nil { bindStage(stage) } else { applyKit(stage: stage); layoutOffsets() }
        active = true; entering = true; sweepPhase = 0
        coreX = screenW * 0.5; coreY = -bodyHalfH - 24
        exploding = false; explosionTimer = 0; activeExpFrame = 0
        victorySequenceTimer = 0; victoryCascadeGate = 0; victoryShatterFired = false
        s5ShowTerminalWreck = false; corePhaseOpen = false; visualFlags = 0; s5CoreArmorBank = 0
        resetDesperationTimers()
        hasDroppedLeftReward = false; hasDroppedRightReward = false; hasDroppedCoreReward = false
        s6SawOneFlankDown = false; s6SawBothFlanksDown = false
        partSfxPlayed = [Bool](repeating: false, count: BossController.MAX_PART_COUNT)
        for p in parts where p.halfW > 0 { p.isDestroyed = false; p.health = p.maxHealth; p.shudderTimer = 0 }
        syncPartWorldPositions()
        updateNode()
        SoundManager.instance.playAlarm()
    }

    func syncPartWorldPositions() {
        for p in parts { p.x = coreX + p.relOffsetX; p.y = coreY + p.relOffsetY }
    }

    func isActive() -> Bool { active }
    func isExploding() -> Bool { exploding }
    func isVictorySequence() -> Bool { triPartBoss && exploding }
    func locksWorldScroll() -> Bool { triPartBoss && exploding }
    func isTriPartBoss() -> Bool { triPartBoss }
    func isCoreVulnerable() -> Bool { parts[1...].allSatisfy { $0.halfW <= 0 || $0.isDestroyed } }
    func getComponents() -> [BossComponent] { parts }
    func getComponentCount() -> Int { BossController.MAX_PART_COUNT }
    func usesStage5Hitboxes() -> Bool { triPartBoss && active && !exploding }
    func consumeStage5Break() -> Bool { let b = s5HitDestroyed; s5HitDestroyed = false; return b }
    func stage5BreakX() -> Float { s5HitDestroyX }; func stage5BreakY() -> Float { s5HitDestroyY }

    func consumeVisualFlags() -> Int { let f = visualFlags; visualFlags = 0; return f }

    func refreshPhaseFlags() {
        if !active || exploding || entering {
            corePhaseOpen = isCoreVulnerable()
            return
        }
        let open = isCoreVulnerable()
        if open && !corePhaseOpen {
            visualFlags |= BossController.FX_PHASE
        }
        corePhaseOpen = open
    }

    func deactivate() {
        active = false; entering = false; exploding = false
        explosionTimer = 0; activeExpFrame = 0
        victorySequenceTimer = 0; victoryCascadeGate = 0; victoryShatterFired = false
        s5ShowTerminalWreck = false; corePhaseOpen = false; visualFlags = 0
        SoundManager.instance.stopAlarm()
        resetDesperationTimers()
        hideBossSprites()
    }

    private func resetDesperationTimers() {
        s1SweepTimer = 0; s1SweepFireTimer = 0; s1SweepDirection = 1
        s2DesperationTimer = 0; s2RingTimer = 0; s2SniperTimer = 0
        s3DesperationAngle = 0; s3SpiralTimer = 0
        s4SpiralTimer = 0; s4SpiralAngle = 0
        s7RingTimer = 0; s7RingAngle = 0
        s8FanTimer = 0
    }

    func checkStage5CollisionAt(worldX: Float, worldY: Float, damage: Int) -> Bool {
        if !active || exploding || !triPartBoss { return false }
        s5HitDestroyed = false
        let left = parts[BossController.TYPE_LEFT_FLANK]
        let right = parts[BossController.TYPE_RIGHT_FLANK]
        let core = parts[BossController.TYPE_CORE]
        let pt = CGPoint(x: CGFloat(worldX), y: CGFloat(worldY))
        if !left.isDestroyed && leftFlankBounds.contains(pt) { applyPartHit(left, damage: damage); return true }
        if !right.isDestroyed && rightFlankBounds.contains(pt) { applyPartHit(right, damage: damage); return true }
        if !core.isDestroyed && coreBounds.contains(pt) { applyCoreHit(core, left: left, right: right, damage: damage); return true }
        return false
    }

    func checkCollisionAt(worldX: Float, worldY: Float, damage: Int) -> Bool {
        checkStage5CollisionAt(worldX: worldX, worldY: worldY, damage: damage)
    }

    func applyStage5AreaDamage(left: Float, top: Float, right: Float, bottom: Float, damage: Int) {
        if !active || exploding || !triPartBoss || damage <= 0 { return }
        s5HitDestroyed = false
        let leftPart = parts[BossController.TYPE_LEFT_FLANK]
        let rightPart = parts[BossController.TYPE_RIGHT_FLANK]
        let core = parts[BossController.TYPE_CORE]
        let area = CGRect(x: CGFloat(left), y: CGFloat(top), width: CGFloat(right-left), height: CGFloat(bottom-top))
        if !leftPart.isDestroyed && leftFlankBounds.intersects(area) { applyPartHit(leftPart, damage: damage) }
        if !rightPart.isDestroyed && rightFlankBounds.intersects(area) { applyPartHit(rightPart, damage: damage) }
        if !core.isDestroyed && coreBounds.intersects(area) { applyCoreHit(core, left: leftPart, right: rightPart, damage: damage) }
    }

    private func applyPartHit(_ part: BossComponent, damage: Int) {
        let dmg = max(1, damage); part.health -= dmg; part.shudderTimer = BossComponent.SHUDDER_DURATION
        if part.health <= 0 {
            part.health = 0; part.isDestroyed = true
            s5HitDestroyed = true; s5HitDestroyX = part.x; s5HitDestroyY = part.y
            grantModuleReward(part.componentType)
        }
    }

    private func applyCoreHit(_ core: BossComponent, left: BossComponent, right: BossComponent, damage: Int) {
        let dmg = max(1, damage); let armored = !left.isDestroyed && !right.isDestroyed
        if !armored { core.shudderTimer = BossComponent.SHUDDER_DURATION }
        if armored {
            s5CoreArmorBank += Float(dmg) * 0.5
            while s5CoreArmorBank >= 1 && core.health > 0 { s5CoreArmorBank -= 1; core.health -= 1 }
        } else { core.health -= dmg }
        if core.health <= 0 {
            core.health = 0; core.isDestroyed = true
            s5HitDestroyed = true; s5HitDestroyX = core.x; s5HitDestroyY = core.y
            grantModuleReward(BossController.TYPE_CORE)
        }
    }

    private func grantModuleReward(_ componentType: Int) {
        if componentType == BossController.TYPE_LEFT_FLANK && !hasDroppedLeftReward {
            hasDroppedLeftReward = true
            let x = Float(leftFlankBounds.midX); let y = Float(leftFlankBounds.midY)
            ScoreManager.instance.addFlankBreakBonus(x: x, y: y)
            PowerUpManager.instance.spawnGuaranteedDrop(x: x, y: y, itemType: ItemType.WEAPON_UP)
        } else if componentType == BossController.TYPE_RIGHT_FLANK && !hasDroppedRightReward {
            hasDroppedRightReward = true
            let x = Float(rightFlankBounds.midX); let y = Float(rightFlankBounds.midY)
            ScoreManager.instance.addFlankBreakBonus(x: x, y: y)
            PowerUpManager.instance.spawnRightFlankDrop(x: x, y: y, playerWeaponPower: s5WeaponPower, bombStock: s5BombStock)
        } else if componentType == BossController.TYPE_CORE && !hasDroppedCoreReward {
            hasDroppedCoreReward = true
            ScoreManager.instance.addCoreKillBonus(x: Float(coreBounds.midX), y: Float(coreBounds.midY))
        }
    }

    func update(dt: Float, playerX: Float, playerY: Float, weapons: EnemyWeaponSystem,
                playerWeaponPower: Int = 1, bombStock: Int = 3, timeline: SpawnTimeline? = nil) {
        s5WeaponPower = playerWeaponPower; s5BombStock = bombStock; stageTimeline = timeline
        if !active { return }
        tickShudder(dt: dt)
        if !exploding { playNewModuleSfx() }
        if exploding {
            if triPartBoss { updateVictory(dt: dt); return }
            explosionTimer += dt
            let idx = Int(explosionTimer / BossController.EXPLODE_FRAME_SEC)
            if idx >= BossController.EXPLODE_FRAME_COUNT { exploding = false; active = false; hideBossSprites(); return }
            else { activeExpFrame = idx }
            updateNode()
            return
        }
        if parts[BossController.TYPE_CORE].isDestroyed {
            if triPartBoss { beginVictory(weapons: weapons); return }
            SoundManager.instance.stopAlarm()
            SoundManager.instance.playSFX(SoundManager.SFX_HEAVY_EXPLOSION)
            exploding = true; explosionTimer = 0; activeExpFrame = 0
            visualFlags |= BossController.FX_DEATH; return
        }
        if entering {
            coreY += BossController.ENTER_SPEED * dt
            if coreY >= hoverY { coreY = hoverY; entering = false; SoundManager.instance.stopAlarm() }
        } else if combatKind == .tank {
            coreX = screenW * 0.5
        } else {
            sweepPhase += dt * BossController.SWEEP_RATE
            coreX = screenW * 0.5 + sinf(sweepPhase) * screenW * BossController.SWEEP_AMP
        }
        syncPartWorldPositions()
        if triPartBoss { syncHitboxes() }
        updateCombat(dt: dt, playerX: playerX, playerY: playerY, weapons: weapons)
        updateNode()
    }

    private func playNewModuleSfx() {
        let heavy: Set<Int> = [
            BossController.TYPE_LEFT_WING, BossController.TYPE_RIGHT_WING,
            BossController.TYPE_STAGE2_LEFT_TREAD, BossController.TYPE_STAGE2_RIGHT_TREAD,
            BossController.TYPE_STAGE3_LEFT_FLAK, BossController.TYPE_STAGE3_RIGHT_FLAK,
            BossController.TYPE_STAGE3_MEGA_CANNON,
            BossController.TYPE_STAGE4_LEFT_MORTAR, BossController.TYPE_STAGE4_RIGHT_MORTAR,
            BossController.TYPE_STAGE4_HEAVY_GATLING,
            BossController.TYPE_WINTER_LEFT_HOWITZER, BossController.TYPE_WINTER_RIGHT_HOWITZER,
            BossController.TYPE_WINTER_BLIZZARD,
            BossController.TYPE_ATOLL_LEFT_GUN, BossController.TYPE_ATOLL_RIGHT_GUN,
            BossController.TYPE_ATOLL_AA,
            BossController.TYPE_LEFT_FLANK, BossController.TYPE_RIGHT_FLANK
        ]
        for i in 0..<BossController.MAX_PART_COUNT {
            let part = parts[i]
            if i != BossController.TYPE_CORE && part.isDestroyed && part.halfW > 0 && !partSfxPlayed[i] {
                partSfxPlayed[i] = true
                if heavy.contains(i) {
                    SoundManager.instance.playSFX(SoundManager.SFX_HEAVY_EXPLOSION)
                } else {
                    SoundManager.instance.playSFX(SoundManager.SFX_SMALL_EXPLOSION)
                }
            }
        }
    }

    private func updateCombat(dt: Float, playerX: Float, playerY: Float, weapons: EnemyWeaponSystem) {
        let bw = bodyHalfW * 2
        switch combatKind {
        case .orbit:
            updateOrbitCombat(dt: dt, playerX: playerX, playerY: playerY, weapons: weapons, bw: bw)
        case .canopy:
            if entering { weapons.resetStage5Boss(); return }
            weapons.updateStage5Boss(dt: dt, centerX: coreX, centerY: coreY, bossWidth: bw,
                                     playerX: playerX, playerY: playerY,
                                     leftDestroyed: parts[1].isDestroyed, rightDestroyed: parts[2].isDestroyed)
        case .plane:
            if entering { weapons.resetStage1Boss(); return }
            weapons.updateStage1Boss(dt: dt, centerX: coreX, centerY: coreY, bossW: bw,
                                     playerX: playerX, playerY: playerY,
                                     leftWingDead: parts[1].isDestroyed, rightWingDead: parts[2].isDestroyed)
            firePlaneDesperation(dt: dt, weapons: weapons)
        case .tank:
            if entering { weapons.resetStage2Boss(); return }
            weapons.updateStage2Boss(dt: dt, cX: coreX, cY: coreY, w: bw, pX: playerX, pY: playerY,
                                     leftTreadDead: parts[4].isDestroyed, rightTreadDead: parts[5].isDestroyed,
                                     turretDead: parts[6].isDestroyed)
            fireTankDesperation(dt: dt, weapons: weapons, playerX: playerX, playerY: playerY)
        case .battleship:
            if entering { weapons.resetStage3Boss(); return }
            weapons.updateStage3Boss(dt: dt, cX: coreX, cY: coreY, w: bw, pX: playerX, pY: playerY,
                                     leftFlakDead: parts[7].isDestroyed, rightFlakDead: parts[8].isDestroyed,
                                     cannonDead: parts[9].isDestroyed)
            fireBattleshipDesperation(dt: dt, weapons: weapons)
        case .jungle:
            if entering { weapons.resetStage4Boss(); return }
            weapons.updateStage4Boss(dt: dt, cX: coreX, cY: coreY, bossW: bw, bossHalfH: bodyHalfH,
                                     pX: playerX, pY: playerY,
                                     leftMortarDead: parts[10].isDestroyed, rightMortarDead: parts[11].isDestroyed,
                                     gatlingDead: parts[12].isDestroyed)
            fireJungleDesperation(dt: dt, weapons: weapons)
        case .winter:
            if entering { weapons.resetStage7Boss(); return }
            weapons.updateStage7Boss(dt: dt, cX: coreX, cY: coreY, bossW: bw, bossHalfH: bodyHalfH,
                                     pX: playerX, pY: playerY,
                                     leftHowitzerDead: parts[10].isDestroyed, rightHowitzerDead: parts[11].isDestroyed,
                                     blizzardDead: parts[12].isDestroyed)
            fireWinterDesperation(dt: dt, weapons: weapons)
        case .atoll:
            if entering { weapons.resetStage8Boss(); return }
            weapons.updateStage8Boss(dt: dt, cX: coreX, cY: coreY, bossW: bw, bossHalfH: bodyHalfH,
                                     pX: playerX, pY: playerY,
                                     leftGunDead: parts[10].isDestroyed, rightGunDead: parts[11].isDestroyed,
                                     aaDead: parts[12].isDestroyed)
            fireAtollDesperation(dt: dt, weapons: weapons)
        }
    }

    private func firePlaneDesperation(dt: Float, weapons: EnemyWeaponSystem) {
        guard isCoreVulnerable() else { return }
        s1SweepTimer += dt * s1SweepDirection
        s1SweepFireTimer -= dt
        if s1SweepFireTimer <= 0 {
            s1SweepFireTimer = BossController.S1_SWEEP_INTERVAL
            let baseAngle = BossController.DOWN_ANGLE
                + sinf(s1SweepTimer * BossController.S1_SWEEP_FREQ) * BossController.S1_SWEEP_AMP
            let ox = coreX
            let oy = coreY - bodyHalfH * 0.10
            var i = -2
            while i <= 2 {
                let ang = baseAngle + Float(i) * BossController.S1_SWEEP_ARC_STEP
                weapons.fireBullet(startX: ox, startY: oy,
                                   velX: cosf(ang) * BossController.S1_SWEEP_SPEED,
                                   velY: sinf(ang) * BossController.S1_SWEEP_SPEED)
                i += 1
            }
        }
    }

    private func fireTankDesperation(dt: Float, weapons: EnemyWeaponSystem, playerX: Float, playerY: Float) {
        guard isCoreVulnerable() else { return }
        s2DesperationTimer += dt
        s2RingTimer -= dt
        if s2RingTimer <= 0 {
            s2RingTimer = BossController.S2_RING_INTERVAL
            let ox = coreX
            let oy = coreY - bodyHalfH * 0.40
            var k = 0
            while k < BossController.S2_RING_COUNT {
                let ang = Float(k) * BossController.S2_RING_STEP
                weapons.fireBullet(startX: ox, startY: oy,
                                   velX: cosf(ang) * BossController.S2_RING_SPEED,
                                   velY: sinf(ang) * BossController.S2_RING_SPEED)
                k += 1
            }
        }
        s2SniperTimer -= dt
        if s2SniperTimer <= 0 {
            s2SniperTimer = BossController.S2_SNIPER_INTERVAL
            let ox = coreX
            let oy = coreY - bodyHalfH * 0.40
            fireAtPlayer(weapons: weapons, originX: ox - BossController.S2_SNIPER_SEP, originY: oy,
                         targetX: playerX, targetY: playerY, speed: BossController.S2_SNIPER_SPEED)
            fireAtPlayer(weapons: weapons, originX: ox + BossController.S2_SNIPER_SEP, originY: oy,
                         targetX: playerX, targetY: playerY, speed: BossController.S2_SNIPER_SPEED)
        }
    }

    private func fireBattleshipDesperation(dt: Float, weapons: EnemyWeaponSystem) {
        guard isCoreVulnerable() else { return }
        s3DesperationAngle += BossController.S3_SPIRAL_SPIN * dt
        s3SpiralTimer -= dt
        if s3SpiralTimer <= 0 {
            s3SpiralTimer = BossController.S3_SPIRAL_INTERVAL
            let ox = coreX
            let oy = coreY - bodyHalfH * 0.12
            var k = 0
            while k < BossController.S3_SPIRAL_COUNT {
                let ang = s3DesperationAngle + Float(k) * BossController.S3_SPIRAL_STEP
                weapons.fireBullet(startX: ox, startY: oy,
                                   velX: cosf(ang) * BossController.S3_SPIRAL_SPEED,
                                   velY: sinf(ang) * BossController.S3_SPIRAL_SPEED)
                k += 1
            }
        }
    }

    private func fireJungleDesperation(dt: Float, weapons: EnemyWeaponSystem) {
        guard isCoreVulnerable() else { return }
        s4SpiralAngle += BossController.S4_SPIRAL_SPIN * dt
        s4SpiralTimer -= dt
        if s4SpiralTimer <= 0 {
            s4SpiralTimer = BossController.S4_SPIRAL_INTERVAL
            let ox = coreX
            let oy = coreY
            let spd = BossController.S4_SPIRAL_SPEED
            var k = 0
            while k < BossController.S4_SPIRAL_COUNT {
                let step = Float(k) * BossController.S4_SPIRAL_STEP
                let aCw = s4SpiralAngle + step
                let aCcw = -s4SpiralAngle + step
                weapons.fireBullet(startX: ox, startY: oy, velX: cosf(aCw) * spd, velY: sinf(aCw) * spd)
                weapons.fireBullet(startX: ox, startY: oy, velX: cosf(aCcw) * spd, velY: sinf(aCcw) * spd)
                k += 1
            }
        }
    }

    private func fireWinterDesperation(dt: Float, weapons: EnemyWeaponSystem) {
        guard isCoreVulnerable() else { return }
        s7RingAngle += BossController.S7_RING_SPIN * dt
        s7RingTimer -= dt
        if s7RingTimer <= 0 {
            s7RingTimer = BossController.S7_RING_INTERVAL
            let ox = coreX
            let oy = coreY
            let spd = BossController.S7_RING_SPEED
            var k = 0
            while k < BossController.S7_RING_COUNT {
                let ang = s7RingAngle + Float(k) * BossController.S7_RING_STEP
                weapons.fireBullet(startX: ox, startY: oy, velX: cosf(ang) * spd, velY: sinf(ang) * spd)
                k += 1
            }
        }
    }

    private func fireAtollDesperation(dt: Float, weapons: EnemyWeaponSystem) {
        guard isCoreVulnerable() else { return }
        s8FanTimer -= dt
        if s8FanTimer <= 0 {
            s8FanTimer = BossController.S8_FAN_INTERVAL
            let ox = coreX
            let oy = coreY + bodyHalfH * 0.912
            let spd = BossController.S8_FAN_SPEED
            var i = -2
            while i <= 2 {
                let ang = BossController.DOWN_ANGLE + Float(i) * BossController.S8_FAN_STEP
                weapons.fireBullet(startX: ox, startY: oy, velX: cosf(ang) * spd, velY: sinf(ang) * spd)
                i += 1
            }
        }
    }

    private func fireAtPlayer(weapons: EnemyWeaponSystem, originX: Float, originY: Float,
                              targetX: Float, targetY: Float, speed: Float) {
        let dx = targetX - originX
        let dy = targetY - originY
        let lenSq = dx * dx + dy * dy
        if lenSq < 0.0001 { return }
        let inv = speed / sqrtf(lenSq)
        weapons.fireBullet(startX: originX, startY: originY, velX: dx * inv, velY: dy * inv)
    }

    private func updateOrbitCombat(dt: Float, playerX: Float, playerY: Float, weapons: EnemyWeaponSystem, bw: Float) {
        if entering { weapons.resetStage6Boss(); return }
        let left = parts[1]; let right = parts[2]
        if left.isDestroyed && right.isDestroyed && !s6SawBothFlanksDown {
            s6SawBothFlanksDown = true; s6SawOneFlankDown = true
            stageTimeline?.forceElapsed(BossController.S6_PHASE3_CLOCK)
        } else if (left.isDestroyed || right.isDestroyed) && !s6SawOneFlankDown {
            s6SawOneFlankDown = true; stageTimeline?.forceElapsed(BossController.S6_PHASE2_CLOCK)
        }
        let bh = bodyHalfH * 2
        weapons.updateStage6Boss(dt: dt,
            leftX: coreX + BossController.S6_LEFT_MUZZLE_X*bw, leftY: coreY + BossController.S6_LEFT_MUZZLE_Y*bh,
            rightX: coreX + BossController.S6_RIGHT_MUZZLE_X*bw, rightY: coreY + BossController.S6_RIGHT_MUZZLE_Y*bh,
            lensX: coreX + BossController.S6_CORE_LENS_X*bw, lensY: coreY + BossController.S6_CORE_LENS_Y*bh,
            playerX: playerX, playerY: playerY,
            leftDestroyed: left.isDestroyed, rightDestroyed: right.isDestroyed)
    }

    private func beginVictory(weapons: EnemyWeaponSystem) {
        SoundManager.instance.stopAlarm(); SoundManager.instance.stopBGM()
        SoundManager.instance.playSFX(SoundManager.SFX_HEAVY_EXPLOSION)
        weapons.convertActiveToScoreItems()
        exploding = true; explosionTimer = 0; victorySequenceTimer = 0
        victoryCascadeGate = 0; victoryShatterFired = false; s5ShowTerminalWreck = false
        visualFlags |= BossController.FX_VICTORY_START
    }

    private func updateVictory(dt: Float) {
        let prev = victorySequenceTimer; victorySequenceTimer += dt; let t = victorySequenceTimer
        if prev < BossController.VICTORY_CASCADE_START && t >= BossController.VICTORY_CASCADE_START { victoryCascadeGate = 0 }
        if t >= BossController.VICTORY_CASCADE_START && t < BossController.VICTORY_SHATTER_AT {
            victoryCascadeGate -= dt
            if victoryCascadeGate <= 0 {
                victoryCascadeGate += BossController.VICTORY_CASCADE_STEP
                spawnVictoryExplosion(); visualFlags |= BossController.FX_VICTORY_CASCADE
            }
        }
        if !victoryShatterFired && t >= BossController.VICTORY_SHATTER_AT {
            victoryShatterFired = true; s5ShowTerminalWreck = true
            for i in 0..<BossController.VICTORY_CLUSTER {
                let u = (Float(i) + 0.5) / Float(BossController.VICTORY_CLUSTER)
                ParticleManager.instance.spawnExplosion(x: coreX - bodyHalfW + u*bodyHalfW*2,
                                                        y: coreY + (nextVictoryUnit()-0.5)*bodyHalfH)
            }
            SoundManager.instance.playSFX(SoundManager.SFX_BOMB); visualFlags |= BossController.FX_VICTORY_SHATTER
        }
        if t >= BossController.VICTORY_END { exploding = false; active = false; hideBossSprites(); return }
        updateNode()
    }

    private func spawnVictoryExplosion() {
        let bounds = [leftFlankBounds, rightFlankBounds, coreBounds][Int(nextVictoryUnit()*3)]
        ParticleManager.instance.spawnExplosion(x: Float(bounds.minX + CGFloat(nextVictoryUnit()) * bounds.width),
                                              y: Float(bounds.minY + CGFloat(nextVictoryUnit()) * bounds.height))
    }
    private func nextVictoryUnit() -> Float {
        victoryLcg = victoryLcg &* 1664525 &+ 1013904223
        return Float((victoryLcg >> 8) & 0xFFFFFF) / 16777215.0
    }

    private func hideBossSprites() {
        bodyNode?.isHidden = true
        leftWreckNode?.isHidden = true
        rightWreckNode?.isHidden = true
        centerWreckNode?.isHidden = true
        leftWreckCrop?.isHidden = true
        rightWreckCrop?.isHidden = true
    }

    private func updateNode() {
        guard let node = bodyNode, let scene = scene else { return }
        if !active { hideBossSprites(); return }
        let size = CGSize(width: CGFloat(bodyHalfW * 2), height: CGFloat(bodyHalfH * 2))
        let pos = CGPoint(x: CGFloat(coreX), y: scene.size.height - CGFloat(coreY))
        let tri = combatKind == .orbit || combatKind == .canopy

        if exploding && !triPartBoss, activeExpFrame >= 0, activeExpFrame < expFrames.count {
            node.isHidden = false
            node.texture = expFrames[activeExpFrame]
            node.size = size
            node.position = pos
            node.zPosition = 36.4
        } else if let tex = bodyTex, !(triPartBoss && s5ShowTerminalWreck) {
            node.isHidden = false
            node.texture = tex
            node.size = size
            node.position = pos
            node.zPosition = 36
        } else {
            node.isHidden = true
        }

        let flags = wreckFlags()
        placeWreck(leftWreckNode, tex: leftWreckTex, show: flags.left, size: size, pos: pos,
                   crop: tri ? leftWreckCrop : nil, leftHalf: true)
        placeWreck(rightWreckNode, tex: rightWreckTex, show: flags.right, size: size, pos: pos,
                   crop: tri ? rightWreckCrop : nil, leftHalf: false)
        if tri {
            leftWreckNode?.isHidden = true
            rightWreckNode?.isHidden = true
        } else {
            leftWreckCrop?.isHidden = true
            rightWreckCrop?.isHidden = true
        }
        if let center = centerWreckNode {
            let showCenter = flags.center && centerWreckTex != nil
            center.isHidden = !showCenter
            if showCenter {
                center.texture = centerWreckTex
                center.size = size
                center.position = pos
            }
        }
        if triPartBoss && s5ShowTerminalWreck, let center = centerWreckNode, centerWreckTex != nil {
            center.isHidden = false
            center.texture = centerWreckTex
            center.size = size
            center.position = pos
            leftWreckCrop?.isHidden = true
            rightWreckCrop?.isHidden = true
        }
    }

    private func wreckFlags() -> (left: Bool, right: Bool, center: Bool) {
        switch combatKind {
        case .orbit, .canopy:
            return (parts[BossController.TYPE_LEFT_FLANK].isDestroyed,
                    parts[BossController.TYPE_RIGHT_FLANK].isDestroyed,
                    false)
        case .atoll:
            return (parts[BossController.TYPE_ATOLL_LEFT_GUN].isDestroyed,
                    parts[BossController.TYPE_ATOLL_RIGHT_GUN].isDestroyed,
                    parts[BossController.TYPE_ATOLL_AA].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        case .winter:
            return (parts[BossController.TYPE_WINTER_LEFT_HOWITZER].isDestroyed,
                    parts[BossController.TYPE_WINTER_RIGHT_HOWITZER].isDestroyed,
                    parts[BossController.TYPE_WINTER_BLIZZARD].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        case .jungle:
            return (parts[BossController.TYPE_STAGE4_LEFT_MORTAR].isDestroyed,
                    parts[BossController.TYPE_STAGE4_RIGHT_MORTAR].isDestroyed,
                    parts[BossController.TYPE_STAGE4_HEAVY_GATLING].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        case .battleship:
            return (parts[BossController.TYPE_STAGE3_LEFT_FLAK].isDestroyed,
                    parts[BossController.TYPE_STAGE3_RIGHT_FLAK].isDestroyed,
                    parts[BossController.TYPE_STAGE3_MEGA_CANNON].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        case .tank:
            return (parts[BossController.TYPE_STAGE2_LEFT_TREAD].isDestroyed,
                    parts[BossController.TYPE_STAGE2_RIGHT_TREAD].isDestroyed,
                    parts[BossController.TYPE_STAGE2_MAIN_TURRET].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        case .plane:
            return (parts[BossController.TYPE_LEFT_WING].isDestroyed,
                    parts[BossController.TYPE_RIGHT_WING].isDestroyed,
                    parts[BossController.TYPE_TURRET].isDestroyed || parts[BossController.TYPE_CORE].isDestroyed)
        }
    }

    private func placeWreck(_ node: SKSpriteNode?, tex: SKTexture?, show: Bool, size: CGSize, pos: CGPoint,
                            crop: SKCropNode?, leftHalf: Bool) {
        guard let tex, show else {
            node?.isHidden = true
            crop?.isHidden = true
            return
        }
        if let crop {
            let sprite = crop.childNode(withName: "wreck") as? SKSpriteNode
            sprite?.texture = tex
            sprite?.size = size
            sprite?.position = .zero
            let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width * 0.5, height: size.height))
            mask.position = CGPoint(x: leftHalf ? -size.width * 0.25 : size.width * 0.25, y: 0)
            crop.maskNode = mask
            crop.position = pos
            crop.isHidden = false
            node?.isHidden = true
        } else if let node {
            node.texture = tex
            node.size = size
            node.position = pos
            node.isHidden = false
        }
    }

    private func syncHitboxes() {
        let bw = bodyHalfW*2; let bh = bodyHalfH*2; let cx = coreX; let cy = coreY
        let (ll,lr,rl,rr,ft,fb,cl,cr,ct,cb): (Float,Float,Float,Float,Float,Float,Float,Float,Float,Float)
        if combatKind == .orbit {
            (ll,lr,rl,rr,ft,fb,cl,cr,ct,cb) = (BossController.S6_LEFT_L,BossController.S6_LEFT_R,BossController.S6_RIGHT_L,BossController.S6_RIGHT_R,BossController.S6_FLANK_T,BossController.S6_FLANK_B,BossController.S6_CORE_L,BossController.S6_CORE_R,BossController.S6_CORE_T,BossController.S6_CORE_B)
        } else {
            (ll,lr,rl,rr,ft,fb,cl,cr,ct,cb) = (BossController.S5_LEFT_L,BossController.S5_LEFT_R,BossController.S5_RIGHT_L,BossController.S5_RIGHT_R,BossController.S5_FLANK_T,BossController.S5_FLANK_B,BossController.S5_CORE_L,BossController.S5_CORE_R,BossController.S5_CORE_T,BossController.S5_CORE_B)
        }
        leftFlankBounds  = CGRect(x: CGFloat(cx+ll*bw), y: CGFloat(cy+ft*bh), width: CGFloat((lr-ll)*bw), height: CGFloat((fb-ft)*bh))
        rightFlankBounds = CGRect(x: CGFloat(cx+rl*bw), y: CGFloat(cy+ft*bh), width: CGFloat((rr-rl)*bw), height: CGFloat((fb-ft)*bh))
        coreBounds       = CGRect(x: CGFloat(cx+cl*bw), y: CGFloat(cy+ct*bh), width: CGFloat((cr-cl)*bw), height: CGFloat((cb-ct)*bh))
    }

    private func tickShudder(dt: Float) {
        for p in parts where p.shudderTimer > 0 { p.shudderTimer -= dt }
        if leftFlankShudder > 0 { leftFlankShudder -= dt }
        if rightFlankShudder > 0 { rightFlankShudder -= dt }
        if coreShudder > 0 { coreShudder -= dt }
    }

    private func loadSheet(stage: Int) {
        let def = StageCatalog.get(stage)
        bodyTex        = StageBitmaps.loadTexture(named: def.bossBodyPath(), keyed: true)
        leftWreckTex   = StageBitmaps.loadTexture(named: def.wreckLeftPath(), keyed: true)
        rightWreckTex  = StageBitmaps.loadTexture(named: def.wreckRightPath(), keyed: true)
        centerWreckTex = StageBitmaps.loadTexture(named: def.wreckCenterPath(), keyed: true)
        if let tex = bodyTex {
            let aspect = tex.size().height / tex.size().width
            bodyHalfW = screenW * BossController.CORE_WIDTH_FRAC * 0.5
            bodyHalfH = bodyHalfW * Float(aspect)
        }
    }

    private func layoutOffsets() {
        for i in 0..<BossController.MAX_PART_COUNT { disablePart(i) }
        let bw = bodyHalfW*2; let bh = bodyHalfH*2
        switch combatKind {
        case .orbit, .canopy:
            let (ll,lr,rl,rr,ft,fb,cl,cr,ct,cb,chp,fhp) = combatKind == .orbit
                ? (BossController.S6_LEFT_L,BossController.S6_LEFT_R,BossController.S6_RIGHT_L,BossController.S6_RIGHT_R,BossController.S6_FLANK_T,BossController.S6_FLANK_B,BossController.S6_CORE_L,BossController.S6_CORE_R,BossController.S6_CORE_T,BossController.S6_CORE_B,BossController.S6_CORE_HP,BossController.S6_FLANK_HP)
                : (BossController.S5_LEFT_L,BossController.S5_LEFT_R,BossController.S5_RIGHT_L,BossController.S5_RIGHT_R,BossController.S5_FLANK_T,BossController.S5_FLANK_B,BossController.S5_CORE_L,BossController.S5_CORE_R,BossController.S5_CORE_T,BossController.S5_CORE_B,BossController.S5_CORE_HP,BossController.S5_FLANK_HP)
            setupPart(0, (cl+cr)*0.5*bw, (ct+cb)*0.5*bh, (cr-cl)*0.5*bw, (cb-ct)*0.5*bh, chp)
            setupPart(1, (ll+lr)*0.5*bw, (ft+fb)*0.5*bh, (lr-ll)*0.5*bw, (fb-ft)*0.5*bh, fhp)
            setupPart(2, (rl+rr)*0.5*bw, (ft+fb)*0.5*bh, (rr-rl)*0.5*bw, (fb-ft)*0.5*bh, fhp)
            syncHitboxes()
        case .plane:
            setupPart(0, 0, 0, bodyHalfW*0.28, bodyHalfH*0.52, BossController.S1_CORE_HP)
            setupPart(1, -bodyHalfW*0.5, -bodyHalfH*0.08, bodyHalfW*0.30, bodyHalfH*0.20, BossController.S1_WING_HP)
            setupPart(2,  bodyHalfW*0.5, -bodyHalfH*0.08, bodyHalfW*0.30, bodyHalfH*0.20, BossController.S1_WING_HP)
            setupPart(3, 0, bodyHalfH*0.46, bodyHalfW*0.12, bodyHalfW*0.12, BossController.S1_TURRET_HP)
        case .tank:
            setupPart(0, 0, 0, bodyHalfW*0.28, bodyHalfH*0.38, BossController.S2_CORE_HP)
            setupPart(4, -bodyHalfW*0.72, 0, bodyHalfW*0.26, bodyHalfH*0.52, BossController.S2_TREAD_HP)
            setupPart(5,  bodyHalfW*0.72, 0, bodyHalfW*0.26, bodyHalfH*0.52, BossController.S2_TREAD_HP)
            setupPart(6, 0, bodyHalfH*0.18, bodyHalfW*0.16, bodyHalfH*0.28, BossController.S2_TURRET_HP)
        case .battleship:
            setupPart(0, 0, -bodyHalfH*0.1, bodyHalfW*0.35, bodyHalfH*0.40, BossController.S3_CORE_HP)
            setupPart(7, -bodyHalfW*0.70, bodyHalfH*0.15, bodyHalfW*0.20, bodyHalfH*0.20, BossController.S3_FLAK_HP)
            setupPart(8,  bodyHalfW*0.70, bodyHalfH*0.15, bodyHalfW*0.20, bodyHalfH*0.20, BossController.S3_FLAK_HP)
            setupPart(9, 0, bodyHalfH*0.45, bodyHalfW*0.30, bodyHalfH*0.25, BossController.S3_CANNON_HP)
        case .jungle:
            setupPart(0, 0, 0, bodyHalfW*0.30, bodyHalfH*0.40, BossController.S4_CORE_HP)
            setupPart(10, -bodyHalfW*0.75, -bodyHalfH*0.10, bodyHalfW*0.18, bodyHalfH*0.22, BossController.S4_MORTAR_HP)
            setupPart(11,  bodyHalfW*0.75, -bodyHalfH*0.10, bodyHalfW*0.18, bodyHalfH*0.22, BossController.S4_MORTAR_HP)
            setupPart(12, 0, bodyHalfH*0.48, bodyHalfW*0.22, bodyHalfH*0.26, BossController.S4_GATLING_HP)
        case .winter:
            setupPart(0, 0, 0, bodyHalfW*0.28, bodyHalfH*0.38, BossController.S7_CORE_HP)
            setupPart(10, -bodyHalfW*0.543, bodyHalfH*0.318, bodyHalfW*0.16, bodyHalfH*0.16, BossController.S7_HOWITZER_HP)
            setupPart(11,  bodyHalfW*0.531, bodyHalfH*0.318, bodyHalfW*0.16, bodyHalfH*0.16, BossController.S7_HOWITZER_HP)
            setupPart(12, 0, bodyHalfH*0.902, bodyHalfW*0.20, bodyHalfH*0.14, BossController.S7_BLIZZARD_HP)
        case .atoll:
            setupPart(0, 0, 0, bodyHalfW*0.28, bodyHalfH*0.36, BossController.S8_CORE_HP)
            setupPart(10, -bodyHalfW*0.650, bodyHalfH*0.205, bodyHalfW*0.14, bodyHalfH*0.14, BossController.S8_GUN_HP)
            setupPart(11,  bodyHalfW*0.648, bodyHalfH*0.203, bodyHalfW*0.14, bodyHalfH*0.14, BossController.S8_GUN_HP)
            setupPart(12, 0, bodyHalfH*0.912, bodyHalfW*0.16, bodyHalfH*0.12, BossController.S8_AA_HP)
        }
    }

    private func disablePart(_ type: Int) {
        let p = parts[type]; p.componentType = type; p.halfW = 0; p.halfH = 0
        p.maxHealth = 0; p.health = 0; p.isDestroyed = true
    }
    private func setupPart(_ type: Int, _ ox: Float, _ oy: Float, _ hw: Float, _ hh: Float, _ hp: Int) {
        let p = parts[type]; p.componentType = type
        p.relOffsetX = ox; p.relOffsetY = oy; p.halfW = hw; p.halfH = hh
        p.maxHealth = hp; p.health = hp; p.isDestroyed = false
    }
}
