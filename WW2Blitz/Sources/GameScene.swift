import UIKit
import SpriteKit

// MARK: - Game States
enum GameState {
    case title, playing, clear, gameOver, demo
    case registration, campaignComplete, interstitial
    case difficultySelect, characterSelect
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
    private var bombStock = 3
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
    private var lastDemoStage = 1
    private var maxStageCleared = 0
    private var bossFought = false
    private var pendingInitials: [Character] = ["A","A","A"]
    private var registrationActiveCharIndex = 0
    private var registrationCurrentChar: Character = "A"
    private var lastTapTime: TimeInterval = 0
    private var touchStartPoint: CGPoint = .zero
    private let prefs = UserDefaults.standard

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0, y: 0)
        stageData = StageData(); StageData.liveInstance = stageData

        // Setup all systems
        player.setup(scene: self)
        bulletManager.setup(scene: self)
        homingMissiles.setup(scene: self)
        enemyManager.setup(scene: self)
        enemyWeapons.setup(scene: self)
        boss.setup(scene: self)
        parallax.setup(scene: self)
        panicBomb.setup(scene: self)
        ui.setup(scene: self)
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
        enterTitle()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != size, size.width > 1, size.height > 1 else { return }
        ui.onSizeChanged(width: size.width, height: size.height)
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
        if lastUpdateTime == 0 { dt = 1.0/60.0 }
        else {
            let raw = Float(currentTime - lastUpdateTime)
            dt = min(raw, 0.05)  // cap to prevent physics explosion
        }
        lastUpdateTime = currentTime

        updateBGM()
        updateState(dt: dt)
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
            parallax.update(baseSpeed: 50 * dt)

        case .difficultySelect, .characterSelect:
            break

        case .interstitial:
            interstitialTimer -= dt
            if interstitialTimer <= 0 { beginPlaying() }

        case .playing:
            updatePlaying(dt: dt)

        case .demo:
            updateDemo(dt: dt)
            attractTimer += dt
            if attractTimer >= 30 { finishDemoToHighScore() }

        case .clear:
            ScoreManager.instance.updateRecap(dt: dt)

        case .gameOver:
            gameOverT += dt
            if gameOverT >= 9 { routeAfterGameOver() }

        case .registration:
            flashT += dt
            parallax.update(baseSpeed: 50 * dt)

        case .campaignComplete:
            creditsTimer += dt
        }

        particles.update(dt: dt)
    }

    private func updatePlaying(dt: Float) {
        updateCombat(dt: dt, demo: false)
    }

    private func updateDemo(dt: Float) {
        demoTimer += dt
        player.setAutoFire(true)
        demoPilot(dt: dt)
        updateCombat(dt: dt, demo: true)
        if demoTimer > 30 { finishDemoToHighScore() }
    }

    private func updateCombat(dt: Float, demo: Bool) {
        let w = Int(size.width); let h = Int(size.height)
        let def = stageData.def

        if !boss.locksWorldScroll() {
            if def.theaterKind == .facility {
                parallax.updateStage5(scrollSpeedY: stageData.scrollSpeedY, dt: dt)
            } else if def.theaterKind == .ascent {
                parallax.updateStage6(scrollSpeedY: stageData.scrollSpeedY, dt: dt,
                                      elapsedTime: timeline.elapsedSeconds())
            } else {
                parallax.update(baseSpeed: stageData.scrollSpeedY * dt)
            }
        }

        player.update(dt: dt)
        if !demo, player.consumeRespawnPowerDrop() {
            spawnRespawnPowerUp()
        }
        bulletManager.update(dt: dt, player: player, screenW: w, homingMissiles: homingMissiles)
        homingMissiles.update(dt: dt, enemyPool: enemyManager.getEnemyPool(),
                              poolSize: enemyManager.getPoolSize(), boss: boss)
        PowerUpManager.instance.items.update(dt: dt, screenW: w, screenH: h,
                                            playerX: player.centerX(), playerY: player.worldY(),
                                            magnetOn: player.isOnField())
        panicBomb.update(dt: dt, screenW: Float(w), screenH: Float(h))

        let allowBoss = !boss.isActive() && !boss.isExploding()
        timeline.update(dt: dt, enemyManager: enemyManager, screenWidth: w, screenHeight: h,
                        boss: boss, bossEnterSeconds: def.bossAtSeconds, allowBoss: allowBoss,
                        playerWeaponPower: player.getWeaponPower(), stageData: stageData)
        enemyManager.update(dt: dt, playerX: player.centerX(), playerY: player.worldY(),
                          weapons: enemyWeapons)
        enemyWeapons.update(dt: dt)
        boss.update(dt: dt, playerX: player.centerX(), playerY: player.worldY(),
                    weapons: enemyWeapons, playerWeaponPower: player.getWeaponPower(),
                    bombStock: bombStock, timeline: timeline)
        if boss.isActive() || boss.isExploding() { bossFought = true }

        if !demo {
            stageData.tickCombatRank(dt: dt, playerAtMaxWeapon: player.getWeaponPower() >= 3)
        }

        resolveBulletCollisions(awardScore: !demo)
        resolvePlayerBulletVsBoss()
        if player.isOnField() {
            resolvePlayerVsEnemies()
            resolvePlayerVsPowerUps()
        }

        let exploded = bulletManager.resolveEnemyBulletsVsPlayer(
            player: player, enemyBullets: enemyWeapons.pool,
            enemyBulletCount: enemyWeapons.getPoolSize(), particles: particles, awardScore: !demo)
        if exploded && !demo && player.isGameOver() { enterGameOver(); return }

        resolvePanicBomb()

        if demo { return }

        while ScoreManager.instance.consumeExtend() { player.grantExtraLife() }

        let flags = boss.consumeVisualFlags()
        if (flags & BossController.FX_VICTORY_START) != 0 {
            SoundManager.instance.playBGM(SoundManager.BGM_VICTORY, loop: false)
        }

        if !demo, bossFought, !boss.isActive(), !boss.isExploding() {
            enterStageClear()
        }

        if player.isGameOver() { enterGameOver() }
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
                let dx = b.x - e.x; let dy = b.y - e.y
                let hitR = enemyManager.halfWOf(e) + 6
                if dx*dx + dy*dy <= hitR*hitR {
                    b.isActive = false; e.health -= 1
                    if e.health <= 0 {
                        destroyEnemy(e, awardScore: awardScore)
                    } else { e.triggerMicroShudder() }
                    break
                }
            }
        }
        for m in homingMissiles.pool where m.isActive {
            for e in enemies where e.isActive {
                let dx = m.x-e.x; let dy = m.y-e.y; let r = enemyManager.halfWOf(e)+8
                if dx*dx+dy*dy <= r*r {
                    m.isActive = false; e.health -= 3
                    if e.health <= 0 { destroyEnemy(e, awardScore: awardScore) }
                    break
                }
            }
        }
    }

    private func resolvePlayerBulletVsBoss() {
        if !boss.isActive() { return }
        if boss.usesStage5Hitboxes() {
            for b in bulletManager.bulletPool where b.isActive {
                if boss.checkCollisionAt(worldX: b.x, worldY: b.y, damage: player.getWeaponPower()) {
                    b.isActive = false
                    if boss.consumeStage5Break() {
                        particles.triggerExplosion(x: boss.stage5BreakX(), y: boss.stage5BreakY())
                        SoundManager.instance.playSFX(SoundManager.SFX_HEAVY_EXPLOSION)
                    }
                }
            }
            for m in homingMissiles.pool where m.isActive {
                if boss.checkCollisionAt(worldX: m.x, worldY: m.y, damage: 1) {
                    m.isActive = false
                    if boss.consumeStage5Break() {
                        particles.triggerExplosion(x: boss.stage5BreakX(), y: boss.stage5BreakY())
                        SoundManager.instance.playSFX(SoundManager.SFX_HEAVY_EXPLOSION)
                    }
                }
            }
            return
        }
        boss.syncPartWorldPositions()
        let padX: Float = 6
        let padY: Float = 16
        let missilePadX = padX + HomingMissileManager.DRAW_W * 0.5
        let missilePadY = padY + HomingMissileManager.DRAW_H * 0.5
        let parts = boss.getComponents()
        let count = boss.getComponentCount()
        for b in bulletManager.bulletPool where b.isActive {
            if hitModularBoss(parts: parts, count: count, x: b.x, y: b.y, padX: padX, padY: padY) {
                b.isActive = false
            }
        }
        for m in homingMissiles.pool where m.isActive {
            if hitModularBoss(parts: parts, count: count, x: m.x, y: m.y, padX: missilePadX, padY: missilePadY) {
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
        if !player.isOnField() { return }
        let px = player.centerX(); let py = player.worldY()
        for e in enemyManager.getEnemyPool() where e.isActive {
            let dx = px-e.x; let dy = py-e.y
            let r = enemyManager.halfWOf(e) + player.coreHitboxRadius
            if dx*dx+dy*dy <= r*r {
                if player.takeDamage() { particles.triggerExplosion(x: px, y: py) }
                return
            }
        }
    }

    private func resolvePlayerVsPowerUps() {
        if !player.isOnField() { return }
        let px = player.centerX(); let py = player.worldY()
        let hitR: Float = 12 * LayoutPx.scale(width: size.width, height: size.height)
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
            ScoreManager.instance.addScore(ScoreManager.instance.scalePoints(points))
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        case PowerUpSlot.ITEM_TYPE_BOMB:
            if bombStock < 3 {
                bombStock += 1
            } else {
                ScoreManager.instance.addScore(ScoreManager.instance.scalePoints(PowerUpManager.BOMB_FULL_SCORE))
            }
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        case PowerUpSlot.ITEM_TYPE_SHIELD:
            player.restoreHits()
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        default:
            if player.getWeaponPower() < 3 {
                player.upgradeWeapon()
            } else {
                ScoreManager.instance.addScore(ScoreManager.instance.scalePoints(PowerUpManager.POWERUP_FULL_SCORE))
            }
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        }
    }

    private func destroyEnemy(_ e: Enemy, awardScore: Bool = true) {
        e.isActive = false
        if awardScore {
            let pts = enemyPoints(e)
            ScoreManager.instance.addScore(ScoreManager.instance.scalePoints(pts))
        }
        particles.triggerExplosion(x: e.x, y: e.y)
        PowerUpManager.instance.dropEnemyLoot(
            x: e.x, y: e.y, enemyType: e.type,
            guaranteedPowerup: e.isRedShipAnchor, stageData: stageData)
        if e.deathClearBullets { enemyWeapons.beginDeathClear(originX: e.x, originY: e.y) }
        if e.diamondLeader { enemyManager.triggerDiamondSplinter() }
    }

    private func spawnRespawnPowerUp() {
        let s = LayoutPx.scale(width: size.width, height: size.height)
        var y = player.worldY() - PowerUpManager.RESPAWN_POWERUP_LIFT * s
        let minY = PowerUpManager.RESPAWN_POWERUP_MIN_Y * s
        if y < minY { y = minY }
        PowerUpManager.instance.items.spawnSway(x: player.centerX(), y: y, type: PowerUpSlot.ITEM_TYPE_POWERUP)
    }

    private func resolvePanicBomb() {
        guard panicBomb.isActive else { return }
        let box = panicBomb.worldRect()
        if box.right <= box.left { return }
        for b in enemyWeapons.pool where b.isActive {
            if b.x >= box.left && b.x <= box.right && b.y >= box.top && b.y <= box.bottom {
                b.isActive = false
                PowerUpManager.instance.spawnBulletCancelDrop(x: b.x, y: b.y)
            }
        }
        for e in enemyManager.getEnemyPool() where e.isActive {
            let ew = enemyManager.halfWOf(e)
            let eh = enemyManager.halfHOf(e)
            if e.x + ew >= box.left && e.x - ew <= box.right &&
                e.y + eh >= box.top && e.y - eh <= box.bottom {
                e.health -= 5
                if e.health <= 0 { destroyEnemy(e) }
            }
        }
        if boss.isActive() {
            boss.applyStage5AreaDamage(left: box.left, top: box.top, right: box.right, bottom: box.bottom, damage: 5)
        }
    }

    private func enemyPoints(_ e: Enemy) -> Int {
        switch e.type {
        case EnemyPoolManager.TYPE_HEAVY:       return 500
        case EnemyPoolManager.TYPE_INTERCEPTOR: return 300
        case EnemyPoolManager.TYPE_KAMIKAZE:    return 200
        default:                                return 100
        }
    }

    // MARK: - State transitions

    private func enterTitle() {
        player.setAutoFire(false)
        cleanupGameplay()
        currentStage = 1
        loadStage(1)
        player.resetWeaponPower()
        player.restoreLives()
        bombStock = 3
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
        SoundManager.instance.playBGM(SoundManager.BGM_TITLE)
    }

    private func enterDemo() {
        gameState = .demo
        attract = .demo
        attractTimer = 0
        demoTimer = 0
        lastDemoStage = pickAttractStage(lastId: lastDemoStage)
        currentStage = lastDemoStage
        loadStage(currentStage)
        player.setMenuHidden(false)
        player.resetForStage()
        player.resetWeaponPower()
        player.restoreLives()
        player.upgradeWeapon(); player.upgradeWeapon()
        player.setAutoFire(true)
        bombStock = 3
        timeline.reset()
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        boss.deactivate(); parallax.resetScroll()
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        SoundManager.instance.playBGM(stageData.def.stageMusicTrack)
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

    private func beginCampaignFromMenu() {
        ScoreManager.instance.reset()
        ScoreManager.instance.armExtends()
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        stageData.difficultyIndex = selectedDifficulty
        currentStage = 1; stageSequence = 1; maxStageCleared = 0
        player.restoreLives(); player.resetWeaponPower()
        player.applyFighterConfiguration(selectedFighter)
        bombStock = 3
        attract = .title; attractTimer = 0
        enterInterstitial()
    }

    private func enterInterstitial() {
        gameState = .interstitial; interstitialTimer = 3.0
        loadStage(currentStage)
        stageData.currentStage = currentStage
        timeline.reset(); player.resetForStage()
        player.setMenuHidden(true)
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        boss.deactivate(); parallax.resetScroll()
        SoundManager.instance.playBGM(stageData.def.stageMusicTrack)
    }

    private func beginPlaying() {
        gameState = .playing
        bossFought = false
        timeline.reset(); player.resetForStage()
        player.setMenuHidden(false)
        player.setAutoFire(false)
        enemyManager.deactivateAll(); enemyWeapons.deactivateAll()
        boss.deactivate(); parallax.resetScroll()
    }

    private func enterStageClear() {
        gameState = .clear
        maxStageCleared = max(maxStageCleared, currentStage)
        ScoreManager.instance.beginRecap(remainingLives: player.getHealth(), remainingBombs: bombStock)
        SoundManager.instance.playBGM(SoundManager.BGM_VICTORY, loop: false)
        cleanupGameplay()
    }

    private func advanceStage() {
        ScoreManager.instance.resetStageCounters()
        if currentStage >= StageCatalog.maxId() {
            gameState = .campaignComplete; creditsTimer = 0
            SoundManager.instance.playBGM(SoundManager.BGM_VICTORY)
            return
        }
        currentStage += 1; stageSequence += 1
        ScoreManager.instance.syncDifficultyMultiplier(selectedDifficulty)
        enterInterstitial()
    }

    private func enterGameOver() {
        SoundManager.instance.stopAlarm()
        gameOverT = 0
        gameState = .gameOver
        cleanupGameplay()
    }

    private func routeAfterGameOver() {
        if HighScoreManager.shared.rankOf(score: ScoreManager.instance.getScore()) >= 0 {
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
        gameState = .registration
        SoundManager.instance.playBGM(SoundManager.BGM_VICTORY, loop: false)
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
    }

    private func loadStage(_ stage: Int) {
        let def = StageCatalog.get(stage)
        stageData.currentStage = stage
        stageData.scrollSpeedY = def.scrollSpeedY
        stageData.bossAtSeconds = def.bossAtSeconds
        theater.load(next: def, width: size.width)
        parallax.setGround(theater.activeFloorTex)
        parallax.setMid(theater.hasOverlayClouds ? theater.midTex : nil)
        parallax.setHigh(theater.hasOverlayClouds ? theater.highTex : nil)
        parallax.setCanopy(def.theaterKind == .facility ? theater.canopyTex : nil)
        enemyManager.bindTheaterSkins(tank: theater.skinTankTex,
                                       destroyer: theater.skinDestroyerTex,
                                       wagon: theater.skinWagonTex)
        boss.bindStage(stage)
    }

    private func updateBGM() {
        // BGM switching handled at state transitions
    }

    private func renderArcadeUI() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3"
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
            demoT: demoTimer,
            flashT: flashT,
            recapFrame: ScoreManager.instance.recapFrameValue(),
            recapPhase: ScoreManager.instance.recapPhaseValue(),
            recapLives: ScoreManager.instance.recapLivesCount(),
            recapBombs: ScoreManager.instance.recapBombsCount(),
            recapGraze: ScoreManager.instance.recapGrazeCount(),
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
        touchStartPoint = loc
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
        case .characterSelect:
            handleCharacterTouch(loc)
        case .playing:
            player.touchBegan(touch, in: self)
            let now = touch.timestamp
            if now - lastTapTime < 0.3 && bombStock > 0 { firePanicBomb() }
            lastTapTime = now
        case .clear:
            if ScoreManager.instance.isRecapReady() { advanceStage() }
        case .gameOver:
            routeAfterGameOver()
        case .registration:
            handleRegistrationTouch(loc)
        case .campaignComplete:
            if HighScoreManager.shared.rankOf(score: ScoreManager.instance.getScore()) >= 0 {
                beginRegistration()
            } else {
                finishDemoToHighScore()
            }
        default: break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        touches.forEach { player.touchMoved($0, in: self) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        touches.forEach { player.touchEnded($0) }
    }

    private func firePanicBomb() {
        guard bombStock > 0 else { return }
        bombStock -= 1
        panicBomb.activate(startX: player.centerX(), startY: player.worldY())
        SoundManager.instance.playSFX(SoundManager.SFX_BOMB)
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
                                              stage: max(maxStageCleared, currentStage),
                                              name: String(pendingInitials))
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
