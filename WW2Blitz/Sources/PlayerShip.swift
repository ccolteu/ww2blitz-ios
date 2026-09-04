import SpriteKit

class PlayerShip {
    // Constants
    static let FRAME_COUNT = 7
    static let IDLE_INDEX  = 3
    static let IDLE_FRAME: Float = 3
    static let SHIP_WIDTH_FRAC: Float = 0.16
    static let TOUCH_GRAB_SCALE: Float = 3.5
    static let P38_SPEED: Float    = 1600
    static let HELLCAT_SPEED: Float = 1150
    static let P38_TETHER: Float    = 1.0
    static let HELLCAT_TETHER: Float = 0.82
    static let TETHER_LIMIT_PX: Float = 40
    static let P38_MUZZLE_X: Float     = 0.22
    static let HELLCAT_MUZZLE_X: Float = 0.58
    static let HELLCAT_FAN_ANGLE: Float = 0.32
    static let P38_FIRE_INTERVAL: Float      = 0.090
    static let P38_FIRE_INTERVAL_P2: Float   = 0.075
    static let HELLCAT_FIRE_INTERVAL: Float  = 0.125
    static let HELLCAT_FIRE_INTERVAL_P2: Float = 0.105
    static let BULLET_SPEED: Float    = 1600
    static let MOVE_THRESHOLD: Float  = 0.5
    static let FRAME_LERP: Float      = 0.2
    static let MUZZLE_Y_FRAC: Float   = 0.38
    static let INVULN_SEC: Float      = 2.0
    static let START_LIVES = 3
    static let MAX_LIVES   = 6
    static let HITS_PER_LIFE = 3
    static let RESPAWN_SEC: Float = 0.4
    static let DEMO_SPEED: Float  = 920
    static let SHADOW_PX: CGFloat = 2
    static let OUTLINE_PX: CGFloat = 3

    let coreHitboxRadius: Float = 8
    let grazeRadius: Float = 24

    private var screenW: Float = 0
    private var screenH: Float = 0
    var halfW: Float = 0
    var halfH: Float = 0

    private(set) var x: Float = 0
    private(set) var y: Float = 0
    private var lives: Int = PlayerShip.START_LIVES
    private var hitsLeft: Int = PlayerShip.HITS_PER_LIFE
    private var weaponPowerLevel: Int = 1
    private var isInvulnerable: Bool = false
    private var invulnTimer: Float = 0
    private var respawnTimer: Float = 0
    private var respawnPowerDropLatched: Bool = false
    private var isGameOverFlag: Bool = false

    // Touch
    private var touchPointerId: UITouch? = nil
    private var lastTouchX: Float = 0
    private var lastTouchY: Float = 0
    private var grabOffsetX: Float = 0
    private var grabOffsetY: Float = 0
    private var targetVelocityX: Float = 0
    private var isDragging: Bool = false
    private var isMovingHorizontal: Bool = false
    private var autoFire: Bool = false

    // Fighter config
    private var classBaseSpeed: Float = PlayerShip.P38_SPEED
    private var responsivenessTether: Float = PlayerShip.P38_TETHER
    private var muzzleFrac: Float = PlayerShip.P38_MUZZLE_X
    private var fanAngle: Float = 0
    private var fireIntervalBase: Float = PlayerShip.P38_FIRE_INTERVAL
    var chosenFighterIndex: Int = 0   // 0 = P-38, 1 = Hellcat

    private var currentFrameIndex: Float = PlayerShip.IDLE_FRAME
    private var targetFrameIndex: Float = PlayerShip.IDLE_FRAME

    // SpriteKit node
    private(set) var node: SKSpriteNode!
    private var frameTextures: [SKTexture] = []

    // MARK: - Setup

    func setup(scene: SKScene) {
        screenW = Float(scene.size.width)
        screenH = Float(scene.size.height)
        loadTextures()
        let tex = frameTextures[PlayerShip.IDLE_INDEX]
        node = SKSpriteNode(texture: tex)
        let drawW = CGFloat(screenW * PlayerShip.SHIP_WIDTH_FRAC)
        let aspect = tex.size().height / tex.size().width
        node.size = CGSize(width: drawW, height: drawW * aspect)
        halfW = Float(node.size.width) * 0.5
        halfH = Float(node.size.height) * 0.5
        x = screenW * 0.5
        y = screenH * 0.22   // SpriteKit: y up, so 0.22 from bottom ≈ 78% from top
        node.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
        node.zPosition = 50
        scene.addChild(node)
        ArcadeOutline.attach(to: node)
    }

    private func loadTextures() {
        let p38Names  = ["player_ship_1","player_ship_2","player_ship_3","player_ship_4",
                         "player_ship_5","player_ship_6","player_ship_7"]
        let hcNames   = ["player_b_1","player_b_2","player_b_3","player_b_4",
                         "player_b_5","player_b_6","player_b_7"]
        let names = chosenFighterIndex == 0 ? p38Names : hcNames
        frameTextures = names.map { GameArt.texture("Images/\($0)") }
    }

    // MARK: - Touch handling

    func touchBegan(_ touch: UITouch, in scene: SKScene) {
        guard touchPointerId == nil else { return }
        let loc = touch.location(in: scene)
        let tx = Float(loc.x); let ty = Float(loc.y)
        let gx = tx - x; let gy = ty - y
        let grab = touchGrabRadius()
        if gx*gx + gy*gy <= grab*grab {
            touchPointerId = touch; lastTouchX = tx; lastTouchY = ty; isDragging = true
            grabOffsetX = gx; grabOffsetY = gy
        }
    }

    func touchMoved(_ touch: UITouch, in scene: SKScene) {
        guard touch == touchPointerId, isDragging else { return }
        let loc = touch.location(in: scene)
        lastTouchX = Float(loc.x)
        lastTouchY = Float(loc.y)
    }

    func touchEnded(_ touch: UITouch) {
        if touch == touchPointerId { releaseSteer() }
    }

    private func releaseSteer() {
        touchPointerId = nil; isDragging = false
        grabOffsetX = 0; grabOffsetY = 0
        isMovingHorizontal = false; targetVelocityX = 0
        targetFrameIndex = PlayerShip.IDLE_FRAME
    }

    // MARK: - Update

    func update(dt: Float) {
        if isDragging, dt > 0.0001 {
            followTether(fingerX: lastTouchX, fingerY: lastTouchY,
                         grabOffsetX: grabOffsetX, grabOffsetY: grabOffsetY, dt: dt)
        }
        if !isMovingHorizontal {
            targetFrameIndex = PlayerShip.IDLE_FRAME
        } else {
            targetFrameIndex = targetVelocityX < 0 ? 0 : 6
        }
        let lerp = min(max(PlayerShip.FRAME_LERP * dt * 60, 0), 1)
        currentFrameIndex += (targetFrameIndex - currentFrameIndex) * lerp
        isMovingHorizontal = false

        if isInvulnerable {
            invulnTimer -= dt
            if invulnTimer <= 0 { invulnTimer = 0; isInvulnerable = false }
        }
        if respawnTimer > 0 {
            respawnTimer -= dt
            if respawnTimer <= 0 {
                respawnTimer = 0
                x = screenW * 0.5; y = screenH * 0.22
                isInvulnerable = true; invulnTimer = PlayerShip.INVULN_SEC
                respawnPowerDropLatched = true
            }
        }

        clamp()

        let frame = max(0, min(Int(currentFrameIndex.rounded()), PlayerShip.FRAME_COUNT - 1))
        if frame < frameTextures.count { node.texture = frameTextures[frame] }
        node.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
        ArcadeOutline.sync(node)

        let showFlash = isInvulnerable && (Int(invulnTimer * 20) & 1) == 0
        node.alpha = (isGameOverFlag || respawnTimer > 0 || showFlash) ? 0 : 1
    }

    func followTether(fingerX: Float, fingerY: Float,
                      grabOffsetX: Float, grabOffsetY: Float, dt: Float) {
        if isGameOverFlag || lives <= 0 || respawnTimer > 0 { return }
        isDragging = true
        var dx = (fingerX - grabOffsetX) - x
        var dy = (fingerY - grabOffsetY) - y
        var dist = sqrtf(dx*dx + dy*dy)
        if dist <= 0.001 { return }
        if dist > PlayerShip.TETHER_LIMIT_PX {
            let s = PlayerShip.TETHER_LIMIT_PX / dist; dx *= s; dy *= s; dist = PlayerShip.TETHER_LIMIT_PX
        }
        let maxMove = classBaseSpeed * dt
        if dist > maxMove {
            let s = maxMove / dist
            x += dx * s * responsivenessTether; y += dy * s * responsivenessTether
        } else { x += dx; y += dy }
        targetVelocityX = dx
        if abs(dx) > PlayerShip.MOVE_THRESHOLD { isMovingHorizontal = true }
        if targetVelocityX < 0 { targetFrameIndex = 0 }
        else if targetVelocityX > 0 { targetFrameIndex = 6 }
        clamp()
    }

    func steerToward(targetX: Float, targetY: Float, dt: Float) {
        if isGameOverFlag || lives <= 0 || respawnTimer > 0 { return }
        let dx = targetX - x; let dy = targetY - y
        let maxStep = PlayerShip.DEMO_SPEED * dt
        let lenSq = dx*dx + dy*dy
        if lenSq > maxStep*maxStep && lenSq > 0.0001 {
            let inv = maxStep / sqrtf(lenSq)
            x += dx*inv; y += dy*inv
        } else { x = targetX; y = targetY }
        targetVelocityX = dx
        isMovingHorizontal = abs(dx) > PlayerShip.MOVE_THRESHOLD
        clamp()
    }

    private func clamp() {
        let padX = screenW * PlayerShip.SHIP_WIDTH_FRAC * 0.5
        let padY = halfH > 1 ? halfH : padX
        x = max(padX, min(screenW - padX, x))
        y = max(padY, min(screenH - padY, y))
    }

    // MARK: - Public accessors

    func centerX() -> Float { x }
    func centerY() -> Float { y }
    /// Android y-down (matches enemies, bullets, pickups).
    func worldY() -> Float { screenH - y }
    func getHitboxX() -> Float { x }
    func getHitboxY() -> Float { y }
    func setMenuHidden(_ hidden: Bool) { node?.isHidden = hidden }
    func isOnField() -> Bool { !isGameOverFlag && lives > 0 && respawnTimer <= 0 }
    func getHealth() -> Int { lives }
    func getHitsLeft() -> Int { hitsLeft }
    func getMaxHitsPerLife() -> Int { PlayerShip.HITS_PER_LIFE }
    func getWeaponPower() -> Int { weaponPowerLevel }
    func upgradeWeapon() { if weaponPowerLevel < 3 { weaponPowerLevel += 1 } }
    func resetWeaponPower() { weaponPowerLevel = 1 }
    func consumeRespawnPowerDrop() -> Bool {
        if !respawnPowerDropLatched { return false }
        respawnPowerDropLatched = false; return true
    }
    func restoreHits() { hitsLeft = PlayerShip.HITS_PER_LIFE }
    func restoreLives() {
        lives = PlayerShip.START_LIVES; hitsLeft = PlayerShip.HITS_PER_LIFE
        respawnTimer = 0; isGameOverFlag = false; respawnPowerDropLatched = false
    }

    /// Extra cabinet body on the same map. Power stays 1; GameScene drops the catchable P.
    func acceptContinueBody() {
        restoreLives()
        resetForStage()
        isInvulnerable = true
        invulnTimer = PlayerShip.INVULN_SEC
        respawnPowerDropLatched = true
    }
    func grantExtraLife() -> Bool {
        if isGameOverFlag || lives >= PlayerShip.MAX_LIVES { return false }
        lives += 1; return true
    }
    func isGameOver() -> Bool { isGameOverFlag }
    func isFiringHeld() -> Bool { (isDragging || autoFire) && !isGameOverFlag && lives > 0 && respawnTimer <= 0 }
    func setAutoFire(_ on: Bool) { autoFire = on }
    func resetForStage() {
        isInvulnerable = false; invulnTimer = 0; respawnTimer = 0
        respawnPowerDropLatched = false; isGameOverFlag = false
        isDragging = false; isMovingHorizontal = false; autoFire = false
        grabOffsetX = 0; grabOffsetY = 0
        touchPointerId = nil; currentFrameIndex = PlayerShip.IDLE_FRAME
        targetFrameIndex = PlayerShip.IDLE_FRAME; targetVelocityX = 0
        x = screenW * 0.5; y = screenH * 0.22; clamp()
    }

    func takeDamage() -> Bool {
        if isInvulnerable || isGameOverFlag || respawnTimer > 0 { return false }
        ScoreManager.instance.markMiss()
        hitsLeft -= 1
        if hitsLeft > 0 {
            isInvulnerable = true; invulnTimer = PlayerShip.INVULN_SEC; return false
        }
        lives -= 1; hitsLeft = PlayerShip.HITS_PER_LIFE; weaponPowerLevel = 1
        StageData.liveInstance?.dumpCombatRankOnDeath()
        releaseSteer()
        if lives <= 0 { lives = 0; isGameOverFlag = true; return true }
        respawnTimer = PlayerShip.RESPAWN_SEC; return true
    }

    // MARK: - Muzzle helpers

    func touchGrabRadius() -> Float { max(halfW, halfH) * PlayerShip.TOUCH_GRAB_SCALE }
    func leftMuzzleX()  -> Float { x - halfW * muzzleFrac }
    func rightMuzzleX() -> Float { x + halfW * muzzleFrac }
    func muzzleXAt(_ frac: Float) -> Float { x + halfW * frac }
    func muzzleY() -> Float { y + halfH * PlayerShip.MUZZLE_Y_FRAC }  // SpriteKit y-up: up = higher y

    func vulcanInterval() -> Float {
        if weaponPowerLevel == 2 {
            return chosenFighterIndex == 1 ? PlayerShip.HELLCAT_FIRE_INTERVAL_P2 : PlayerShip.P38_FIRE_INTERVAL_P2
        }
        return fireIntervalBase
    }

    func applyFighterConfiguration(_ typeIndex: Int) {
        if typeIndex == 1 {
            chosenFighterIndex = 1
            classBaseSpeed = PlayerShip.HELLCAT_SPEED
            responsivenessTether = PlayerShip.HELLCAT_TETHER
            muzzleFrac = PlayerShip.HELLCAT_MUZZLE_X
            fanAngle = PlayerShip.HELLCAT_FAN_ANGLE
            fireIntervalBase = PlayerShip.HELLCAT_FIRE_INTERVAL
        } else {
            chosenFighterIndex = 0
            classBaseSpeed = PlayerShip.P38_SPEED
            responsivenessTether = PlayerShip.P38_TETHER
            muzzleFrac = PlayerShip.P38_MUZZLE_X
            fanAngle = 0
            fireIntervalBase = PlayerShip.P38_FIRE_INTERVAL
        }
        loadTextures()
        if node != nil, !frameTextures.isEmpty {
            node.texture = frameTextures[PlayerShip.IDLE_INDEX]
            ArcadeOutline.sync(node)
        }
    }
}
