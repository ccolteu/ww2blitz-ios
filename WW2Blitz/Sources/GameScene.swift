import UIKit
import SpriteKit

// MARK: - Game States
enum GameState {
    case title, playing, clear, gameOver, demo
    case registration, campaignComplete, interstitial
    case difficultySelect, characterSelect, continueSelect, continuePrompt
}

class GameScene: SKScene {
    // Systems
    private let player         = PlayerShip()
    private let bulletManager  = BulletManager()
    private let homingMissiles = HomingMissileManager()
    private let enemyManager   = EnemyPoolManager()
    private let enemyWeapons   = EnemyWeaponSystem()
    private let boss           = BossController()
    private let parallax       = ParallaxBackground()
    private let panicBomb      = PanicBomb()
    private let timeline       = SpawnTimeline()
    private let ui             = UIController()
    private let theater        = StageTheater()
    private var particles: ParticleManager!

    // State
    private var gameState: GameState = .title
    private var stageData = StageData()
    private var currentStage = 1
    private var stageSequence = 1
    private var bombStock = 2
    private var continuesRemaining = 0
    private var continuedThisCredit = false
    private var continuePromptT: Float = 0
    private var selectedDifficulty = 3
    private var selectedFighter = 0
    private var interstitialTimer: Float = 3.0
    private var lastUpdateTime: TimeInterval = 0
    private var demoTimer: Float = 0
    private var creditsTimer: Float = 0
    private var gameOverT: Float = 0
    private var flashT: Float = 0
    private var attract: UIController.Attract = .title
    private var attractTimer: Float = 0
    private var settingsOpen = false
    private var lastDemoStage = 0
    private var maxStageCleared = 0
    private var bossFought = false
    private var enemyBombDmgBank: Float = 0
    private var bossBombDmgBank: Float = 0
    private var bombCoreWasOpen = false
    private var pendingInitials: [Character] = ["A","A","A"]
    private var registrationActiveCharIndex = 0
    private var registrationCurrentChar: Character = "A"
    private var awaitingSecondTap = false
    private var lastTapUpTime: TimeInterval = 0
    private var touchDownTime: TimeInterval = 0
    private var touchDownPoint: CGPoint = .zero
    private var shakeDuration: Float = 0
    private var shakeIntensity: Float = 0
    private var shakeSeed: UInt64 = 14352451
    private var shakeDx: CGFloat = 0
    private var shakeDy: CGFloat = 0
    private var flashDuration: Float = 0
    private var flashPeak: Float = 0.25
    private var flashWhiteDecay = false
    private var flashNode: SKSpriteNode?
    private let hudLayer = SKNode()
    private var worldCamera: SKCameraNode?
    private var stage8CanopyShown = false
    private var floatScores: [(node: SKLabelNode, age: Float)] = []
    private let prefs = UserDefaults.standard

    private static let doubleTapSeconds: TimeInterval = 0.280
    private static let tapMaxSeconds: TimeInterval = 0.220
    private static let tapSlopSq: CGFloat = 48 * 48

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0, y: 0)
        stageData = StageData(); StageData.liveInstance = stageData

        hudLayer.name = "hudLayer"
        hudLayer.zPosition = 200
        addChild(hudLayer)
        let flash = SKSpriteNode(color: .white, size: size)
        flash.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        flash.zPosition = 190
        flash.isHidden = true
        flash.alpha = 0
        hudLayer.addChild(flash)
        flashNode = flash
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(cam)
        camera = cam
        worldCamera = cam

        // Setup all systems
        player.setup(scene: self)
        bulletManager.setup(scene: self)
        homingMissiles.setup(scene: self)
        enemyManager.setup(scene: self)
        enemyWeapons.setup(scene: self)
        boss.setup(scene: self)
        parallax.setup(scene: self)
        panicBomb.setup(scene: self)
        ui.setup(scene: self, hudParent: hudLayer)
        particles = ParticleManager()
        particles.setup(scene: self, screenWidth: size.width)
        PowerUpManager.instance.items.setup(scene: self)

        let w = Int(size.width); let h = Int(size.height)
        enemyWeapons.onSizeChanged(width: w, height: h)
        boss.onSizeChanged(width: w, height: h)
        ui.onSizeChanged(width: size.width, height: size.height)
        PowerUpManager.instance.items.onSizeChanged(width: size.width, height: size.height)

        selectedDifficulty = prefs.object(forKey: "ww2_difficulty") == nil
            ? 3 : max(1, min(7, prefs.integer(forKey: "ww2_difficulty")))
        selectedFighter = prefs.integer(forKey: "ww2_fighter")
        player.applyFighterConfiguration(selectedFighter)
        stageData.difficultyIndex = selectedDifficulty
        stageData.loadPersistentSettings()
        enterTitle()
        syncParallaxDraw()
        renderArcadeUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != size, size.width > 1, size.height > 1 else { return }
        ui.onSizeChanged(width: size.width, height: size.height)
        restCamera()
        flashNode?.size = size
        flashNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        enemyWeapons.onSizeChanged(width: Int(size.width), height: Int(size.height))
        boss.onSizeChanged(width: Int(size.width), height: Int(size.height))
        bulletManager.onSizeChanged(width: size.width, height: size.height)
        homingMissiles.onSizeChanged(width: size.width, height: size.height)
        particles?.onSizeChanged(screenWidth: size.width)
        PowerUpManager.instance.items.onSizeChanged(width: size.width, height: size.height)
        enemyManager.onSizeChanged(width: Int(size.width), height: Int(size.height))
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt: Float
        if lastUpdateTime == 0 { dt = 0 }
        else {
            let raw = Float(currentTime - lastUpdateTime)
            dt = min(raw, 0.05)
        }
        lastUpdateTime = currentTime

        updateBGM()
        updateState(dt: dt)
        syncParallaxDraw()
        applyScreenShake(dt: dt)
        applyScreenFlash(dt: dt)
        renderArcadeUI()
    }

    private func updateState(dt: Float) {
        switch gameState {
        case .title:
            if settingsOpen {
                flashT += dt
            } else {
                attractTimer += dt
                if attract == .title && attractTimer >= 4 && size.width > 0 {
                    attractTimer = 0
                    enterDemo()
                } else if attract == .highScore && attractTimer >= 4 {
                    attractTimer = 0
                    attract = .title
                }
            }

        case .difficultySelect, .characterSelect, .continueSelect:
            break

        case .interstitial:
            interstitialTimer -= dt
            if interstitialTimer <= 0 {
                interstitialTimer = 0
                beginPlaying()
            }

        case .playing:
            updatePlaying(dt: dt)

        case .demo:
            updateDemo(dt: dt)

        case .clear:
            tickParallax(scrollSpeedY: 0, dt: dt)
            ScoreManager.instance.updateRecap(dt: dt)
            applyPendingExtends()
            updateFloatingScores(dt: dt)
            particles.update(dt: dt)

        case .gameOver:
            tickParallax(scrollSpeedY: 0, dt: dt)
            particles.update(dt: dt)
            gameOverT += dt
            if gameOverT >= 9 { routeAfterGameOver() }

        case .continuePrompt:
            tickParallax(scrollSpeedY: 0, dt: dt)
            particles.update(dt: dt)
            continuePromptT += dt
            if continuePromptT >= 9 { enterGameOver() }

        case .registration:
            flashT += dt
            tickParallax(scrollSpeedY: 50, dt: dt)

        case .campaignComplete:
            tickParallax(scrollSpeedY: 0, dt: dt)
            particles.update(dt: dt)
            updateFloatingScores(dt: dt)
            creditsTimer += dt
        }
    }

    private func updatePlaying(dt: Float) {
        updateCombat(dt: dt, demo: false)
    }

    private func updateDemo(dt: Float) {
        player.setAutoFire(true)
        updateCombat(dt: dt, demo: true)
    }

    private func tickParallax(scrollSpeedY: Float, dt: Float) {
        let def = stageData.def
        if def.theaterKind == .facility {
            parallax.updateStage7(scrollSpeedY: scrollSpeedY, dt: dt)
        } else if def.theaterKind == .ascent {
            parallax.updateStage8(scrollSpeedY: scrollSpeedY, dt: dt,
                                  elapsedTime: timeline.elapsedSeconds())
        } else {
            parallax.update(baseSpeed: scrollSpeedY * dt)
        }
    }

    private func updateCombat(dt: Float, demo: Bool) {
        let w = Int(size.width); let h = Int(size.height)
        let def = stageData.def

        if boss.locksWorldScroll() {
            stageData.scrollSpeedY = 0
            tickParallax(scrollSpeedY: 0, dt: dt)
        } else {
            tickParallax(scrollSpeedY: stageData.scrollSpeedY, dt: dt)
        }
        maybeShowStage8Canopy()

        if demo {
            demoPilot(dt: dt)
        }
        player.update(dt: dt)
        if !demo, dt > 0.0001, player.isOnField() {
            stageData.tickCombatRank(dt: dt, playerAtMaxWeapon: player.getWeaponPower() >= 3)
        }
        if !demo, player.consumeRespawnPowerDrop() {
            spawnRespawnPowerUp()
        }
        bulletManager.update(dt: dt, player: player, screenW: w, homingMissiles: homingMissiles)
        homingMissiles.update(dt: dt, enemyPool: enemyManager.getEnemyPool(),
                              poolSize: enemyManager.getPoolSize(), boss: boss)
        PowerUpManager.instance.items.update(dt: dt, screenW: w, screenH: h,
                                            playerX: player.centerX(), playerY: player.worldY(),
                                            magnetOn: player.isOnField())
        updateFloatingScores(dt: dt)

        timeline.update(dt: dt, enemyManager: enemyManager, screenWidth: w, screenHeight: h,
                        boss: boss, bossEnterSeconds: def.bossAtSeconds, allowBoss: true,
                        playerWeaponPower: player.getWeaponPower(), stageData: stageData)
        maybeSwapStage8Floor()
        enemyManager.update(dt: dt, playerX: player.centerX(), playerY: player.worldY(),
                          weapons: enemyWeapons)
        boss.update(dt: dt, playerX: player.centerX(), playerY: player.worldY(),
                    weapons: enemyWeapons, playerWeaponPower: player.getWeaponPower(),
                    bombStock: bombStock, timeline: timeline)
        maybeSwapStage8Floor()
        if boss.isActive() || boss.isExploding() { bossFought = true }
        enemyWeapons.update(dt: dt)
        panicBomb.update(dt: dt, screenW: Float(w), screenH: Float(h))
        resolvePanicBomb(dt: dt)
        particles.update(dt: dt)

        if player.getHealth() <= 0 {
            if !demo { offerContinueOrGameOver() }
        } else {
            resolveBulletCollisions(awardScore: !demo)
            resolvePlayerBulletVsBoss()

            let exploded = bulletManager.resolveEnemyBulletsVsPlayer(
                player: player, enemyBullets: enemyWeapons.pool,
                enemyBulletCount: enemyWeapons.getPoolSize(), particles: particles, awardScore: !demo)
            if exploded && !demo && player.isGameOver() { offerContinueOrGameOver() }

            if player.isOnField() {
                resolvePlayerVsEnemies()
                resolvePlayerVsBoss()
                resolvePlayerVsPowerUps()
            }
        }

        if !demo { applyPendingExtends() }

        boss.refreshPhaseFlags()
        let pulse = boss.consumeVisualFlags()
        if pulse & BossController.FX_PHASE != 0 {
            triggerScreenShake(duration: 0.18, intensity: 10)
            triggerScreenFlash(0.08)
        }
        if pulse & BossController.FX_DEATH != 0 {
            triggerScreenShake(duration: 0.42, intensity: 22)
            triggerScreenFlash(0.14)
        }
        if pulse & BossController.FX_VICTORY_CASCADE != 0 {
            triggerScreenShake(duration: 0.1, intensity: 8)
        }
        if pulse & BossController.FX_VICTORY_SHATTER != 0 {
            triggerWhiteFlash(0.25)
        }

        if demo {
            demoTimer += dt
            attractTimer += dt
            if attractTimer >= 30 { finishDemoToHighScore() }
            return
        }

        if gameState == .playing, bossFought, !boss.isActive(), !boss.isExploding() {
            enterStageClear()
        }

        if gameState == .playing, player.isGameOver() { offerContinueOrGameOver() }
    }

    /// Attract CPU: sit near the bottom, slide under the lowest threat, dodge incoming shots.
    private func demoPilot(dt: Float) {
        let w = Float(size.width); let h = Float(size.height)
        let px = player.centerX()
        let py = player.worldY()
        var huntX = w * 0.5 + sinf(demoTimer * 1.15) * (w * 0.16)
        let huntWorldY = h * 0.78
        var bestY: Float = -1
        for e in enemyManager.getEnemyPool() where e.isActive {
            if e.y > 48 && e.y < py - 56 {
                if e.y > bestY {
                    bestY = e.y
                    huntX = e.x
                }
            }
        }
        if boss.isActive() {
            let parts = boss.getComponents()
            for pi in 0..<boss.getComponentCount() {
                let part = parts[pi]
                if !part.isDestroyed && part.halfW > 0 && part.y < py - 40 {
                    if part.y > bestY {
                        bestY = part.y
                        huntX = part.x
                    }
                }
            }
        }
        let dodgeMargin: Float = 78
        for b in enemyWeapons.pool where b.isActive {
            if b.vy > 0 && b.y < py && b.y > py - 240 {
                let dx = b.x - px
                if dx * dx < dodgeMargin * dodgeMargin {
                    huntX += b.x >= px ? -120 : 120
                    break
                }
            }
        }
        huntX = min(max(huntX, w * 0.12), w * 0.88)
        player.steerToward(targetX: huntX, targetY: h - huntWorldY, dt: dt)
    }

    // MARK: - Collision resolution

    private func resolveBulletCollisions(awardScore: Bool) {
        let pool = bulletManager.bulletPool
        let enemies = enemyManager.getEnemyPool()
        for b in pool where b.isActive {
            for e in enemies where e.isActive {
                if shotHitsEnemy(dx: b.x - e.x, dy: b.y - e.y, enemy: e) {
                    b.isActive = false
                    e.health -= 1
                    if e.type == EnemyPoolManager.TYPE_HEAVY { e.triggerMicroShudder() }
                    if e.health <= 0 {
                        destroyEnemy(e, awardScore: awardScore, revenge: true)
                    }
                    break
                }
            }
        }
        for m in homingMissiles.pool where m.isActive {
            for e in enemies where e.isActive {
                if shotHitsEnemy(dx: m.x - e.x, dy: m.y - e.y, enemy: e) {
                    m.isActive = false
                    e.health -= 1
                    if e.type == EnemyPoolManager.TYPE_HEAVY { e.triggerMicroShudder() }
                    if e.health <= 0 {
                        destroyEnemy(e, awardScore: awardScore, revenge: true)
                    }
                    break
                }
            }
        }
    }

    private func shotHitsEnemy(dx: Float, dy: Float, enemy: Enemy) -> Bool {
        let popcorn = enemy.type != EnemyPoolManager.TYPE_INTERCEPTOR && enemy.type != EnemyPoolManager.TYPE_HEAVY
        let pad: Float = popcorn ? 3 : 10
        let frac: Float = popcorn ? 0.28 : 0.55
        let sx = pad + enemyManager.halfWOf(enemy) * frac
        let sy = pad + enemyManager.halfHOf(enemy) * frac
        if sx <= 0 || sy <= 0 { return false }
        let nx = dx / sx
        let ny = dy / sy
        return nx * nx + ny * ny <= 1
    }

    private func resolvePlayerBulletVsBoss() {
        if !boss.isActive() { return }
        if boss.usesStage7Hitboxes() {
            for b in bulletManager.bulletPool where b.isActive {
                if boss.checkCollisionAt(worldX: b.x, worldY: b.y, damage: 1) {
                    b.isActive = false
                    if boss.consumeStage7Break() {
                        particles.triggerExplosion(x: boss.stage7BreakX(), y: boss.stage7BreakY(), playSound: false)
                    }
                }
            }
            for m in homingMissiles.pool where m.isActive {
                if boss.checkCollisionAt(worldX: m.x, worldY: m.y, damage: 1) {
                    m.isActive = false
                    if boss.consumeStage7Break() {
                        particles.triggerExplosion(x: boss.stage7BreakX(), y: boss.stage7BreakY(), playSound: false)
                    }
                }
            }
            return
        }
        boss.syncPartWorldPositions()
        let padX: Float = 6
        let padY: Float = 16
        let parts = boss.getComponents()
        let count = boss.getComponentCount()
        for b in bulletManager.bulletPool where b.isActive {
            if hitModularBoss(parts: parts, count: count, x: b.x, y: b.y, padX: padX, padY: padY) {
                b.isActive = false
            }
        }
        for m in homingMissiles.pool where m.isActive {
            if hitModularBoss(parts: parts, count: count, x: m.x, y: m.y, padX: padX, padY: padY) {
                m.isActive = false
            }
        }
    }

    @discardableResult
    private func hitModularBoss(parts: [BossComponent], count: Int, x: Float, y: Float,
                                padX: Float, padY: Float) -> Bool {
        var i = count - 1
        while i >= 0 {
            let part = parts[i]
            if !part.isDestroyed && part.halfW > 0 && part.halfH > 0 {
                let hw = part.halfW + padX
                let hh = part.halfH + padY
                let dx = (x - part.x) / hw
                let dy = (y - part.y) / hh
                if dx * dx + dy * dy <= 1 {
                    if part.componentType != BossController.TYPE_CORE || boss.isCoreVulnerable() {
                        part.health -= 1
                        part.triggerMicroShudder()
                        if part.health <= 0 {
                            part.health = 0
                            part.isDestroyed = true
                            particles.triggerExplosion(x: part.x, y: part.y, playSound: false)
                        }
                    }
                    return true
                }
            }
            i -= 1
        }
        return false
    }

    private func resolvePlayerVsEnemies() {
        if !player.isOnField() || player.isGameOver() { return }
        let px = player.centerX(); let py = player.worldY()
        let playerRadius: Float = 12
        let ramBody: Float = 0.45
        for e in enemyManager.getEnemyPool() where e.isActive {
            let sx = playerRadius + enemyManager.halfWOf(e) * ramBody
            let sy = playerRadius + enemyManager.halfHOf(e) * ramBody
            if sx <= 0 || sy <= 0 { continue }
            let nx = (e.x - px) / sx
            let ny = (e.y - py) / sy
            if nx * nx + ny * ny <= 1 {
                destroyEnemy(e, awardScore: gameState == .playing, revenge: false)
                if player.takeDamage() {
                    particles.triggerExplosion(x: px, y: py)
                    if player.isGameOver() && gameState == .playing { offerContinueOrGameOver() }
                }
                return
            }
        }
    }

    private func resolvePlayerVsBoss() {
        if player.isGameOver() || !player.isOnField() || !boss.isActive() || boss.isExploding() { return }
        let px = player.centerX(); let py = player.worldY()
        let playerRadius: Float = 12
        boss.syncPartWorldPositions()
        let parts = boss.getComponents()
        let count = boss.getComponentCount()
        var i = 0
        while i < count {
            let part = parts[i]
            if !part.isDestroyed && part.halfW > 0 && part.halfH > 0 {
                let rx = part.halfW + playerRadius
                let ry = part.halfH + playerRadius
                let nx = (px - part.x) / rx
                let ny = (py - part.y) / ry
                if nx * nx + ny * ny <= 1 {
                    if player.takeDamage() {
                        particles.triggerExplosion(x: px, y: py)
                        if player.isGameOver() && gameState == .playing { offerContinueOrGameOver() }
                    }
                    break
                }
            }
            i += 1
        }
    }

    private func resolvePlayerVsPowerUps() {
        if !player.isOnField() { return }
        let px = player.centerX(); let py = player.worldY()
        let hitR: Float = 12
        for slot in PowerUpManager.instance.items.pool where slot.isActive {
            let dx = px-slot.x; let dy = py-slot.y
            let half = PowerUpManager.instance.items.drawHalf(forType: slot.itemType)
            let pickup = hitR + half
            if dx*dx+dy*dy <= pickup*pickup {
                slot.isActive = false
                collectItem(slot)
            }
        }
    }

    private func collectItem(_ item: PowerUpSlot) {
        switch item.itemType {
        case PowerUpSlot.ITEM_TYPE_MEDAL:
            let points = item.pickupPoints > 0
                ? item.pickupPoints
                : (item.medalFrameIndex == 0 ? PowerUpManager.MEDAL_SCORE_FACE : PowerUpManager.MEDAL_SCORE_EDGE)
            ScoreManager.instance.addPickupScore(x: item.x, y: item.y, base: points)
            if item.isSecretMedal { ScoreManager.instance.collectSecretMedal() }
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        case PowerUpSlot.ITEM_TYPE_BOMB:
            if bombStock < 3 {
                bombStock += 1
            } else {
                ScoreManager.instance.addPickupScore(x: item.x, y: item.y, base: PowerUpManager.BOMB_FULL_SCORE)
            }
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        case PowerUpSlot.ITEM_TYPE_SHIELD:
            player.restoreHits()
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        default:
            if player.getWeaponPower() < 3 {
                player.upgradeWeapon()
            } else {
                ScoreManager.instance.addPickupScore(x: item.x, y: item.y, base: PowerUpManager.POWERUP_FULL_SCORE)
            }
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        }
    }

    private func destroyEnemy(_ e: Enemy, awardScore: Bool = true, revenge: Bool = false) {
        if awardScore {
            ScoreManager.instance.addKillScore(x: e.x, y: e.y, base: enemyPoints(e))
        }
        if revenge { fireRevengeIfNeeded(e) }
        e.isActive = false
        particles.triggerExplosion(x: e.x, y: e.y)
        PowerUpManager.instance.dropEnemyLoot(
            x: e.x, y: e.y, enemyType: e.type,
            guaranteedPowerup: e.isRedShipAnchor, isMidBoss: e.isMidBoss,
            bombStock: bombStock, stageData: stageData)
        if e.deathClearBullets { enemyWeapons.beginDeathClear(originX: e.x, originY: e.y) }
        if e.diamondLeader { enemyManager.triggerDiamondSplinter() }
    }

    private func fireRevengeIfNeeded(_ enemy: Enemy) {
        if enemy.deathClearBullets { return }
        if enemy.isMidBoss { return }
        let popcorn = enemy.type != EnemyPoolManager.TYPE_INTERCEPTOR
            && enemy.type != EnemyPoolManager.TYPE_HEAVY
        if !stageData.revengeOnDeath() {
            if !popcorn || !stageData.popcornSuicide() { return }
        }
        let px = player.centerX()
        let py = player.worldY()
        let dx = px - enemy.x
        let dy = py - enemy.y
        let lenSq = dx * dx + dy * dy
        if lenSq <= 0.0001 { return }
        let speed = 550 * stageData.shotSpeedScale()
        let inv = speed / sqrtf(lenSq)
        let vx = dx * inv
        let vy = dy * inv
        if enemy.type == EnemyPoolManager.TYPE_HEAVY && stageData.difficultyIndex == 7 {
            let ang = atan2f(vy, vx)
            let spread: Float = 0.18
            enemyWeapons.fireBullet(startX: enemy.x, startY: enemy.y, velX: cosf(ang - spread) * speed, velY: sinf(ang - spread) * speed)
            enemyWeapons.fireBullet(startX: enemy.x, startY: enemy.y, velX: vx, velY: vy)
            enemyWeapons.fireBullet(startX: enemy.x, startY: enemy.y, velX: cosf(ang + spread) * speed, velY: sinf(ang + spread) * speed)
        } else {
            enemyWeapons.fireBullet(startX: enemy.x, startY: enemy.y, velX: vx, velY: vy)
        }
    }

    private func spawnRespawnPowerUp() {
        let s = LayoutPx.scale(width: size.width, height: size.height)
        var y = player.worldY() - PowerUpManager.RESPAWN_POWERUP_LIFT * s
        let minY = PowerUpManager.RESPAWN_POWERUP_MIN_Y * s
        if y < minY { y = minY }
        PowerUpManager.instance.items.spawnSway(x: player.centerX(), y: y, type: PowerUpSlot.ITEM_TYPE_POWERUP)
    }

    private func resolvePanicBomb(dt: Float) {
        guard panicBomb.isActive else {
            enemyBombDmgBank = 0
            bossBombDmgBank = 0
            return
        }
        let box = panicBomb.worldRect()
        if box.right <= box.left { return }
        for b in enemyWeapons.pool where b.isActive {
            if b.x >= box.left && b.x <= box.right && b.y >= box.top && b.y <= box.bottom {
                b.isActive = false
            }
        }
        enemyBombDmgBank += 250 * dt
        let enemyDmg = Int(enemyBombDmgBank)
        if enemyDmg > 0 {
            enemyBombDmgBank -= Float(enemyDmg)
            for e in enemyManager.getEnemyPool() where e.isActive {
                let ew = enemyManager.halfWOf(e)
                let eh = enemyManager.halfHOf(e)
                if e.x + ew >= box.left && e.x - ew <= box.right &&
                    e.y + eh >= box.top && e.y - eh <= box.bottom {
                    e.health -= enemyDmg
                    if e.type == EnemyPoolManager.TYPE_HEAVY { e.triggerMicroShudder() }
                    if e.health <= 0 { destroyEnemy(e) }
                }
            }
        }
        if boss.isActive(), !boss.isExploding() {
            bossBombDmgBank += 200 * dt
            var dmg = Int(bossBombDmgBank)
            if dmg > 0 {
                bossBombDmgBank -= Float(dmg)
                if dmg > 12 { dmg = 12 }
                applyBombDamageToBoss(box: box, damage: dmg)
            }
        }
    }

    private func applyBombDamageToBoss(box: (left: Float, top: Float, right: Float, bottom: Float), damage: Int) {
        if boss.usesStage7Hitboxes() {
            boss.applyStage7AreaDamage(left: box.left, top: box.top, right: box.right, bottom: box.bottom, damage: damage)
            if boss.consumeStage7Break() {
                particles.triggerExplosion(x: boss.stage7BreakX(), y: boss.stage7BreakY())
            }
            return
        }
        boss.syncPartWorldPositions()
        let parts = boss.getComponents()
        var i = boss.getComponentCount() - 1
        while i >= 0 {
            let part = parts[i]
            if !part.isDestroyed && part.halfW > 0 && part.halfH > 0 {
                if part.x + part.halfW >= box.left && part.x - part.halfW <= box.right &&
                    part.y + part.halfH >= box.top && part.y - part.halfH <= box.bottom {
                    if part.componentType == BossController.TYPE_CORE && !bombCoreWasOpen {
                        i -= 1
                        continue
                    }
                    part.health -= damage
                    part.triggerMicroShudder()
                    if part.health <= 0 {
                        part.health = 0
                        part.isDestroyed = true
                        particles.triggerExplosion(x: part.x, y: part.y)
                    }
                }
            }
            i -= 1
        }
    }

    private func enemyPoints(_ e: Enemy) -> Int {
        switch e.type {
        case EnemyPoolManager.TYPE_HEAVY:       return 1000
        case EnemyPoolManager.TYPE_INTERCEPTOR: return 300
        default:                                return 100
        }
    }

    // MARK: - State transitions

    private func enterTitle() {
        player.setAutoFire(false)
        cleanupGameplay()
        stageData.resetToStart()
        stageData.resetCombatRank()
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        currentStage = stageData.currentStage
        loadCurrentStage()
        player.resetWeaponPower()
        player.restoreLives()
        bombStock = 2
        ScoreManager.instance.reset()
        maxStageCleared = 0
        bossFought = false
        attractTimer = 0
        attract = .title
        demoTimer = 0
        gameOverT = 0
        settingsOpen = false
        gameState = .title
        player.setMenuHidden(true)
    }

    private func enterDemo() {
        gameState = .demo
        attract = .demo
        attractTimer = 0
        demoTimer = 0
        lastDemoStage = pickAttractStage(lastId: lastDemoStage)
        stageData.setCurrentStage(lastDemoStage)
        currentStage = stageData.currentStage
        loadCurrentStage()
        stageData.resetCombatRank()
        player.setMenuHidden(false)
        player.resetForStage()
        player.resetWeaponPower()
        player.restoreLives()
        player.upgradeWeapon(); player.upgradeWeapon()
        player.setAutoFire(true)
        bombStock = 2
        timeline.reset()
        armHiddenMedalRoute()
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        boss.deactivate(); parallax.resetScroll()
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
    }

    private func pickAttractStage(lastId: Int) -> Int {
        let catalog = StageCatalog.all
        let eligible = catalog.filter { !$0.introOnly }
        if eligible.isEmpty { return catalog[0].id }
        var seed = UInt64(Date().timeIntervalSince1970 * 1_000_000)
        var pick = lastId
        for _ in 0..<32 {
            seed = seed &* 1664525 &+ 1013904223
            let def = catalog[Int((seed >> 16) & 0xFFFF) % catalog.count]
            if !def.introOnly {
                pick = def.id
                if eligible.count == 1 || pick != lastId { return pick }
            }
        }
        return eligible[0].id
    }

    private func enterDifficultySelect() {
        gameState = .difficultySelect
        SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
    }

    private func enterCharacterSelect() {
        selectedFighter = player.chosenFighterIndex
        gameState = .characterSelect
        SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
    }

    private func enterContinueSelect() {
        attractTimer = 0
        attract = .title
        gameState = .continueSelect
        SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
    }

    private func beginCampaignFromMenu() {
        ScoreManager.instance.reset()
        ScoreManager.instance.armExtends()
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        stageData.difficultyIndex = selectedDifficulty
        stageData.resetToStart()
        stageData.resetCombatRank()
        currentStage = stageData.currentStage
        stageSequence = stageData.missionNumber
        maxStageCleared = 0
        player.restoreLives(); player.resetWeaponPower()
        player.applyFighterConfiguration(selectedFighter)
        bombStock = 2
        continuesRemaining = stageData.getContinueDip()
        continuedThisCredit = false
        attract = .title; attractTimer = 0
        enterInterstitial()
    }

    private func enterInterstitial() {
        gameState = .interstitial; interstitialTimer = 3.0
        loadCurrentStage()
        bossFought = false
        timeline.reset(); player.resetForStage()
        armHiddenMedalRoute()
        player.setMenuHidden(true)
        player.setAutoFire(false)
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        bulletManager.deactivateAll(); homingMissiles.deactivateAll()
        PowerUpManager.instance.items.deactivateAll()
        panicBomb.deactivate()
        particles.hideDrawn()
        enemyBombDmgBank = 0
        bossBombDmgBank = 0
        bombCoreWasOpen = false
        awaitingSecondTap = false
        boss.deactivate(); parallax.resetScroll()
    }

    private func beginPlaying() {
        gameState = .playing
        player.setMenuHidden(false)
        player.setAutoFire(false)
    }

    private func enterStageClear() {
        gameState = .clear
        if stageData.missionNumber > maxStageCleared {
            maxStageCleared = stageData.missionNumber
        }
        ScoreManager.instance.beginRecap(remainingLives: player.getHealth(), remainingBombs: bombStock)
        cleanupGameplay()
    }

    private func advanceStage() {
        ScoreManager.instance.resetStageCounters()
        if stageData.isLastInSequence() {
            hidePlayfieldSprites()
            gameState = .campaignComplete; creditsTimer = 0
            return
        }
        stageData.advanceToNextStage()
        currentStage = stageData.currentStage
        stageSequence = stageData.missionNumber
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        enterInterstitial()
    }

    private func offerContinueOrGameOver() {
        if gameState != .playing { return }
        if continuesRemaining > 0 {
            SoundManager.instance.stopAlarm()
            continuePromptT = 0
            gameState = .continuePrompt
            return
        }
        enterGameOver()
    }

    private func acceptContinueCredit() {
        if continuesRemaining <= 0 {
            enterGameOver()
            return
        }
        continuesRemaining -= 1
        continuedThisCredit = true
        bombStock = 2
        player.resetWeaponPower()
        player.acceptContinueBody()
        SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        gameState = .playing
        player.setMenuHidden(false)
    }

    private func enterGameOver() {
        SoundManager.instance.stopAlarm()
        gameOverT = 0
        gameState = .gameOver
    }

    private func qualifiesForRanking() -> Bool {
        if continuedThisCredit { return false }
        return HighScoreManager.shared.checkIfQualifies(
            score: ScoreManager.instance.getScore(), difficulty: selectedDifficulty)
    }

    private func routeAfterGameOver() {
        if qualifiesForRanking() {
            beginRegistration()
        } else {
            finishDemoToHighScore()
        }
    }

    private func beginRegistration() {
        pendingInitials = ["A","A","A"]
        registrationActiveCharIndex = 0
        registrationCurrentChar = "A"
        flashT = 0
        hidePlayfieldSprites()
        gameState = .registration
    }

    private func finishDemoToHighScore() {
        enterTitle()
        attract = .highScore
        attractTimer = 0
    }

    private func cleanupGameplay() {
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        boss.deactivate(); bulletManager.deactivateAll()
        homingMissiles.deactivateAll(); PowerUpManager.instance.items.deactivateAll()
        panicBomb.deactivate()
        hidePlayfieldSprites()
        enemyBombDmgBank = 0
        bossBombDmgBank = 0
        bombCoreWasOpen = false
        awaitingSecondTap = false
        shakeDuration = 0
        shakeIntensity = 0
        shakeDx = 0
        shakeDy = 0
        flashDuration = 0
        flashWhiteDecay = false
        flashNode?.isHidden = true
        flashNode?.alpha = 0
        hudLayer.position = .zero
        restCamera()
        for item in floatScores { item.node.removeFromParent() }
        floatScores.removeAll()
    }

    /// Android skips gameplay blit on clear / registration / credits / briefing.
    private func hidePlayfieldSprites() {
        player.setMenuHidden(true)
        enemyManager.deactivateAll()
        enemyWeapons.deactivateAll()
        bulletManager.deactivateAll()
        homingMissiles.deactivateAll()
        PowerUpManager.instance.items.deactivateAll()
        panicBomb.deactivate()
        boss.deactivate()
        particles.hideDrawn()
    }

    private func loadCurrentStage() {
        stageData.bindCurrentPlaylistSlot()
        currentStage = stageData.currentStage
        let def = stageData.def
        theater.load(next: def, width: size.width)
        stage8CanopyShown = false
        parallax.setGround(theater.activeFloorTex)
        parallax.setMid(theater.hasOverlayClouds ? theater.midTex : nil)
        parallax.setHigh(theater.hasOverlayClouds ? theater.highTex : nil)
        parallax.setCanopy(def.theaterKind == .facility ? theater.canopyTex : nil)
        enemyManager.bindTheaterSkins(tank: theater.skinTankTex,
                                       destroyer: theater.skinDestroyerTex,
                                       wagon: theater.skinWagonTex,
                                       helicopter: theater.skinHelicopterTex)
        boss.bindStage(currentStage)
        armHiddenMedalRoute()
    }

    private func armHiddenMedalRoute() {
        HiddenMedalRoute.bind(stageData.currentStage)
        ScoreManager.instance.armSecretRoute(HiddenMedalRoute.cueCountValue())
    }

    private func maybeSwapStage8Floor() {
        let def = stageData.def
        if def.theaterKind != .ascent { return }
        if theater.floorSwapped { return }
        if timeline.elapsedSeconds() < def.spaceSwapAt { return }
        theater.swapToFloorAlt()
        parallax.replaceGround(theater.activeFloorTex)
    }

    private func maybeShowStage8Canopy() {
        let def = stageData.def
        if def.theaterKind != .ascent || stage8CanopyShown { return }
        if timeline.elapsedSeconds() < def.canopyAt { return }
        stage8CanopyShown = true
        parallax.setCanopy(theater.canopyTex)
    }

    private func updateFloatingScores(dt: Float) {
        let h = Float(size.height)
        while ScoreManager.instance.hasPopup() {
            let label = SKLabelNode(fontNamed: ArcadeTypeface.postScriptName)
            label.text = "\(ScoreManager.instance.popupValue())"
            label.fontSize = 20
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 180
            let ax = ScoreManager.instance.popupX()
            let ay = ScoreManager.instance.popupY()
            label.position = CGPoint(x: CGFloat(ax), y: CGFloat(h - ay))
            hudLayer.addChild(label)
            floatScores.append((label, 0))
            if floatScores.count > 48 {
                floatScores[0].node.removeFromParent()
                floatScores.removeFirst()
            }
            ScoreManager.instance.consumePopup()
        }
        var i = 0
        while i < floatScores.count {
            floatScores[i].age += dt
            floatScores[i].node.position.y += CGFloat(90 * dt)
            let life: Float = 0.75
            let u = max(0, 1 - floatScores[i].age / life)
            floatScores[i].node.alpha = CGFloat(u)
            if floatScores[i].age >= life {
                floatScores[i].node.removeFromParent()
                floatScores.remove(at: i)
            } else {
                i += 1
            }
        }
    }

    private func updateBGM() {
        let want: String?
        switch gameState {
        case .title, .difficultySelect, .characterSelect, .continueSelect:
            want = SoundManager.BGM_TITLE
        case .clear, .registration, .campaignComplete:
            want = SoundManager.BGM_VICTORY
        case .playing, .demo, .interstitial, .continuePrompt:
            if boss.isVictorySequence() {
                want = nil
            } else if boss.isActive() {
                want = boss.isCoreVulnerable() ? SoundManager.BGM_BOSS2 : SoundManager.BGM_BOSS
            } else {
                want = stageData.def.stageMusicTrack
            }
        case .gameOver:
            want = nil
        }
        if let track = want {
            SoundManager.instance.playBGM(track)
        } else {
            SoundManager.instance.stopBGM()
        }
    }

    private func syncParallaxDraw() {
        let def = stageData.def
        let facility = def.theaterKind == .facility
        switch gameState {
        case .title, .difficultySelect, .characterSelect, .continueSelect, .interstitial:
            parallax.applyDrawFlags(worldVisible: false, overlayClouds: false, canopyVisible: false)
        case .registration:
            parallax.applyDrawFlags(worldVisible: true, overlayClouds: true, canopyVisible: false)
        case .campaignComplete:
            parallax.applyDrawFlags(worldVisible: true, overlayClouds: false, canopyVisible: facility)
        case .clear:
            parallax.applyDrawFlags(
                worldVisible: true,
                overlayClouds: !facility && def.hasOverlayClouds,
                canopyVisible: facility)
        case .playing, .demo, .gameOver, .continuePrompt:
            let canopy: Bool
            if facility {
                canopy = true
            } else if def.theaterKind == .ascent {
                canopy = stage8CanopyShown
            } else {
                canopy = false
            }
            parallax.applyDrawFlags(
                worldVisible: true,
                overlayClouds: def.hasOverlayClouds,
                canopyVisible: canopy)
        }
    }

    private func renderArcadeUI() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.4"
        ui.render(
            state: gameState,
            attract: attract,
            settingsOpen: settingsOpen,
            difficulty: selectedDifficulty,
            fighterIndex: player.chosenFighterIndex,
            lives: player.getHealth(),
            hitsLeft: player.getHitsLeft(),
            maxHits: player.getMaxHitsPerLife(),
            bombs: bombStock,
            score: ScoreManager.instance.getScore(),
            gameOverT: gameOverT,
            continuePromptT: continuePromptT,
            continuesRemaining: continuesRemaining,
            continueDip: stageData.getContinueDip(),
            demoT: demoTimer,
            flashT: flashT,
            recapFrame: ScoreManager.instance.recapFrameValue(),
            recapPhase: ScoreManager.instance.recapPhaseValue(),
            recapLives: ScoreManager.instance.recapLivesCount(),
            recapBombs: ScoreManager.instance.recapBombsCount(),
            recapGraze: ScoreManager.instance.recapGrazeCount(),
            recapNoMiss: ScoreManager.instance.recapNoMissBonus(),
            recapNoBomb: ScoreManager.instance.recapNoBombBonus(),
            recapSecretCount: ScoreManager.instance.recapSecretCollected(),
            recapSecretUnit: ScoreManager.instance.recapSecretUnit(),
            recapTotal: ScoreManager.instance.recapBonusTotal(),
            stage: currentStage,
            briefing: theater.briefingTex,
            interstitialTimer: interstitialTimer,
            creditsT: creditsTimer,
            pendingInitials: pendingInitials,
            activeCharIndex: registrationActiveCharIndex,
            currentChar: registrationCurrentChar,
            highScores: HighScoreManager.shared,
            version: version
        )
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        if gameState == .demo || (gameState == .title && attract == .highScore) {
            enterTitle()
            return
        }

        switch gameState {
        case .title:
            attractTimer = 0; attract = .title
            handleTitleTouch(loc)
        case .difficultySelect:
            handleDifficultyTouch(loc)
        case .continueSelect:
            handleContinueSelectTouch(loc)
        case .characterSelect:
            handleCharacterTouch(loc)
        case .playing:
            maybeFireDoubleTapBomb(timestamp: touch.timestamp)
            player.touchBegan(touch, in: self)
            touchDownTime = touch.timestamp
            touchDownPoint = loc
        case .clear:
            break
        case .gameOver:
            routeAfterGameOver()
        case .continuePrompt:
            acceptContinueCredit()
        case .registration:
            handleRegistrationTouch(loc)
        case .campaignComplete:
            if qualifiesForRanking() {
                beginRegistration()
            } else {
                finishDemoToHighScore()
            }
        default: break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .title {
            attractTimer = 0
            attract = .title
        }
        guard gameState == .playing else { return }
        touches.forEach { player.touchMoved($0, in: self) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .clear {
            if ScoreManager.instance.isRecapReady() { advanceStage() }
            return
        }
        guard gameState == .playing else { return }
        for touch in touches {
            finishTap(touch)
            player.touchEnded(touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        for touch in touches {
            finishTap(touch)
            player.touchEnded(touch)
        }
    }

    private func maybeFireDoubleTapBomb(timestamp: TimeInterval) {
        if awaitingSecondTap &&
            timestamp - lastTapUpTime <= Self.doubleTapSeconds &&
            bombStock > 0 &&
            !player.isGameOver() {
            firePanicBomb()
            awaitingSecondTap = false
        }
    }

    private func finishTap(_ touch: UITouch) {
        let loc = touch.location(in: self)
        let dx = loc.x - touchDownPoint.x
        let dy = loc.y - touchDownPoint.y
        let dur = touch.timestamp - touchDownTime
        awaitingSecondTap = (dx * dx + dy * dy) <= Self.tapSlopSq && dur <= Self.tapMaxSeconds
        lastTapUpTime = touch.timestamp
    }

    private func firePanicBomb() {
        guard bombStock > 0, !panicBomb.isActive, !player.isGameOver() else { return }
        bombStock -= 1
        bombCoreWasOpen = boss.isCoreVulnerable()
        bossBombDmgBank = 0
        panicBomb.activate(startX: player.centerX(), startY: player.worldY())
        ScoreManager.instance.markBombUsed()
        addScreenShake(0.8)
        SoundManager.instance.playSFX(SoundManager.SFX_BOMB)
    }

    private func applyPendingExtends() {
        while ScoreManager.instance.consumeExtend() {
            if player.grantExtraLife() {
                SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            }
        }
    }

    private func addScreenShake(_ intensity: Float) {
        let mag = max(0, intensity)
        triggerScreenShake(duration: 0.28, intensity: 12 + mag * 22)
    }

    private func triggerScreenShake(duration: Float, intensity: Float) {
        shakeDuration = max(0, duration)
        shakeIntensity = max(0, intensity)
    }

    private func triggerScreenFlash(_ duration: Float) {
        flashDuration = max(0, duration)
        flashWhiteDecay = false
    }

    private func triggerWhiteFlash(_ duration: Float) {
        let dur = max(0, duration)
        flashDuration = dur
        flashPeak = dur <= 0 ? 0.25 : dur
        flashWhiteDecay = true
    }

    private func applyScreenFlash(dt: Float) {
        guard let flash = flashNode else { return }
        if flashDuration > 0 {
            flash.isHidden = false
            if flashWhiteDecay {
                let peak = max(flashPeak, 0.0001)
                flash.color = .white
                flash.alpha = CGFloat(max(0, min(1, flashDuration / peak)))
            } else {
                flash.color = .white
                flash.alpha = 102 / 255
            }
            flashDuration -= dt
            if flashDuration < 0 { flashDuration = 0 }
        } else {
            flash.isHidden = true
            flash.alpha = 0
        }
    }

    private func restCamera() {
        worldCamera?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    }

    private func nextShakeUnit() -> Float {
        shakeSeed = shakeSeed &* 1664525 &+ 1013904223
        return Float((shakeSeed >> 8) & 0xFFFFFF) / 16_777_215
    }

    private func applyScreenShake(dt: Float) {
        if shakeDuration > 0 {
            let mag = CGFloat(shakeIntensity)
            shakeDx = CGFloat(nextShakeUnit() * 2 - 1) * mag
            shakeDy = CGFloat(nextShakeUnit() * 2 - 1) * mag
            worldCamera?.position = CGPoint(
                x: size.width * 0.5 + shakeDx,
                y: size.height * 0.5 + shakeDy)
            hudLayer.position = CGPoint(x: shakeDx, y: shakeDy)
            shakeDuration -= dt
            if shakeDuration < 0 { shakeDuration = 0 }
        } else {
            shakeDx = 0
            shakeDy = 0
            restCamera()
            hudLayer.position = .zero
        }
    }

    private func bumpVolume(_ current: Float, up: Bool) -> Float {
        let slots = 10
        let cur = min(slots, max(0, Int(current * Float(slots) + 0.5)))
        let next = min(slots, max(0, up ? cur + 1 : cur - 1))
        return Float(next) / Float(slots)
    }

    private func handleTitleTouch(_ loc: CGPoint) {
        let h = ui.hits
        if settingsOpen {
            if h.bgmDown.contains(loc) {
                SoundManager.instance.setBgmVolumeScale(bumpVolume(SoundManager.instance.getBgmVolumeScale(), up: false))
            } else if h.bgmUp.contains(loc) {
                SoundManager.instance.setBgmVolumeScale(bumpVolume(SoundManager.instance.getBgmVolumeScale(), up: true))
            } else if h.sfxDown.contains(loc) {
                SoundManager.instance.setSfxVolumeScale(bumpVolume(SoundManager.instance.getSfxVolumeScale(), up: false))
                SoundManager.instance.playSFX(SoundManager.SFX_VULCAN)
            } else if h.sfxUp.contains(loc) {
                SoundManager.instance.setSfxVolumeScale(bumpVolume(SoundManager.instance.getSfxVolumeScale(), up: true))
                SoundManager.instance.playSFX(SoundManager.SFX_VULCAN)
            } else if h.settingsBack.contains(loc) {
                settingsOpen = false
                SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            }
            return
        }
        if h.audio.contains(loc) {
            settingsOpen = true; flashT = 0
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        } else if h.difficulty.contains(loc) {
            enterDifficultySelect()
        } else if h.continueMenu.contains(loc) {
            enterContinueSelect()
        } else if h.fighter.contains(loc) {
            enterCharacterSelect()
        } else {
            beginCampaignFromMenu()
        }
    }

    private func handleDifficultyTouch(_ loc: CGPoint) {
        if ui.hits.diffBack.contains(loc) {
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            enterTitle()
            return
        }
        for i in 0..<7 where ui.hits.diffRows[i].contains(loc) {
            selectedDifficulty = i + 1
            stageData.difficultyIndex = selectedDifficulty
            prefs.set(selectedDifficulty, forKey: "ww2_difficulty")
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            break
        }
    }

    private func handleContinueSelectTouch(_ loc: CGPoint) {
        if ui.hits.continueBack.contains(loc) {
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            enterTitle()
            return
        }
        for i in 0..<3 where ui.hits.continueRows[i].contains(loc) {
            stageData.saveContinueSetting(i)
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            break
        }
    }

    private func handleCharacterTouch(_ loc: CGPoint) {
        if ui.hits.shipLeft.contains(loc) {
            selectedFighter = 0
            player.applyFighterConfiguration(0)
            prefs.set(0, forKey: "ww2_fighter")
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        } else if ui.hits.shipRight.contains(loc) {
            selectedFighter = 1
            player.applyFighterConfiguration(1)
            prefs.set(1, forKey: "ww2_fighter")
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        } else if ui.hits.fighterBack.contains(loc) {
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            enterTitle()
        }
    }

    private func handleRegistrationTouch(_ loc: CGPoint) {
        if ui.hits.regSet.contains(loc) {
            pendingInitials[registrationActiveCharIndex] = registrationCurrentChar
            registrationActiveCharIndex += 1
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
            if registrationActiveCharIndex >= 3 {
                HighScoreManager.shared.insert(score: ScoreManager.instance.getScore(),
                                              stage: maxStageCleared,
                                              name: String(pendingInitials),
                                              difficulty: selectedDifficulty)
                finishDemoToHighScore()
            } else {
                registrationCurrentChar = "A"
            }
        } else if ui.hits.regLeft.contains(loc) {
            registrationCurrentChar = registrationCurrentChar == "A" ? "Z"
                : Character(UnicodeScalar(registrationCurrentChar.asciiValue! - 1))
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        } else if ui.hits.regRight.contains(loc) {
            registrationCurrentChar = registrationCurrentChar == "Z" ? "A"
                : Character(UnicodeScalar(registrationCurrentChar.asciiValue! + 1))
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        }
    }
}
