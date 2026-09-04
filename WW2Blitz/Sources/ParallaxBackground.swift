import SpriteKit

/// Three-layer vertical parallax background in SpriteKit.
/// Uses duplicate sprite nodes for seamless tiling.
class ParallaxBackground {
    private static let SPEED_GROUND: CGFloat = 1.0
    private static let SPEED_MID:    CGFloat = 1.5
    private static let SPEED_HIGH:   CGFloat = 2.2
    private static let SPEED_S5_LAYER2: CGFloat = 1.5
    private static let S6_CLOUD_END:   Float = 15.0
    private static let S6_BURN_END:    Float = 35.0
    private static let S6_BURN_SPAN:   Float = 20.0
    private static let S6_BURN_PEAK:   Float = 3.5
    private static let S6_ORBIT_END:   Float = 45.0
    private static let S6_ORBIT_SPAN:  Float = 10.0
    private static let S6_ORBIT_FLOOR: Float = 0.4
    private static let S6_BRAKE_END:   Float = 50.0
    private static let S6_BRAKE_SPAN:  Float = 5.0
    private static let MID_ALPHA: CGFloat  = 140.0/255
    private static let HIGH_ALPHA: CGFloat = 36.0/255

    // Node pairs (tiled: tile A + tile B for seamless wrapping)
    private var groundA: SKSpriteNode?
    private var groundB: SKSpriteNode?
    private var midA: SKSpriteNode?
    private var midB: SKSpriteNode?
    private var highA: SKSpriteNode?
    private var highB: SKSpriteNode?
    private var canopyA: SKSpriteNode?
    private var canopyB: SKSpriteNode?

    private var groundHeight: CGFloat = 0
    private var midHeight:    CGFloat = 0
    private var highHeight:   CGFloat = 0
    private var canopyHeight: CGFloat = 0

    private var yGround: CGFloat = 0
    private var yMid:    CGFloat = 0
    private var yHigh:   CGFloat = 0
    private var yCanopy: CGFloat = 0
    var stage6SpeedModifier: Float = 1.0

    private weak var scene: SKScene?
    private var sceneW: CGFloat = 0
    private var sceneH: CGFloat = 0

    func setup(scene: SKScene) {
        self.scene = scene
        sceneW = scene.size.width; sceneH = scene.size.height
    }

    func setGround(_ tex: SKTexture?, altTex: SKTexture? = nil) {
        groundA?.removeFromParent(); groundB?.removeFromParent()
        guard let tex = tex, let scene = scene else { return }
        let h = tex.size().height * sceneW / tex.size().width
        groundHeight = h
        groundA = makeTileNode(tex: tex, z: -20, alpha: 1); groundB = makeTileNode(tex: tex, z: -20, alpha: 1)
        scene.addChild(groundA!); scene.addChild(groundB!)
        placeGroundTiles()
    }

    func setMid(_ tex: SKTexture?) {
        midA?.removeFromParent(); midB?.removeFromParent()
        midA = nil; midB = nil
        guard let tex = tex, let scene = scene else { midHeight = 0; return }
        let h = tex.size().height * sceneW / tex.size().width
        midHeight = h
        midA = makeTileNode(tex: tex, z: -18, alpha: ParallaxBackground.MID_ALPHA, blendMode: .screen)
        midB = makeTileNode(tex: tex, z: -18, alpha: ParallaxBackground.MID_ALPHA, blendMode: .screen)
        scene.addChild(midA!); scene.addChild(midB!)
    }

    func setHigh(_ tex: SKTexture?) {
        highA?.removeFromParent(); highB?.removeFromParent()
        highA = nil; highB = nil
        guard let tex = tex, let scene = scene else { highHeight = 0; return }
        let h = tex.size().height * sceneW / tex.size().width
        highHeight = h
        highA = makeTileNode(tex: tex, z: -16, alpha: ParallaxBackground.HIGH_ALPHA, blendMode: .screen)
        highB = makeTileNode(tex: tex, z: -16, alpha: ParallaxBackground.HIGH_ALPHA, blendMode: .screen)
        scene.addChild(highA!); scene.addChild(highB!)
    }

    func setCanopy(_ tex: SKTexture?) {
        canopyA?.removeFromParent(); canopyB?.removeFromParent()
        canopyA = nil; canopyB = nil
        guard let tex = tex, let scene = scene else { canopyHeight = 0; return }
        let h = tex.size().height * sceneW / tex.size().width
        canopyHeight = h
        // Android draws canopy after enemies/shots and before missiles/player bullets.
        canopyA = makeTileNode(tex: tex, z: 38, alpha: 1); canopyB = makeTileNode(tex: tex, z: 38, alpha: 1)
        scene.addChild(canopyA!); scene.addChild(canopyB!)
    }

    func replaceGround(_ tex: SKTexture?) {
        guard let tex = tex else { return }
        let h = tex.size().height * sceneW / tex.size().width
        groundHeight = h
        groundA?.texture = tex
        groundB?.texture = tex
        groundA?.size = CGSize(width: sceneW, height: h)
        groundB?.size = CGSize(width: sceneW, height: h)
        placeGroundTiles()
    }

    private func makeTileNode(tex: SKTexture, z: CGFloat, alpha: CGFloat, blendMode: SKBlendMode = .alpha) -> SKSpriteNode {
        let n = SKSpriteNode(texture: tex)
        let h = tex.size().height * sceneW / tex.size().width
        n.size = CGSize(width: sceneW, height: h)
        n.anchorPoint = CGPoint(x: 0, y: 0); n.zPosition = z; n.alpha = alpha; n.blendMode = blendMode
        return n
    }

    func update(baseSpeed: Float) {
        yGround = wrapY(yGround - CGFloat(baseSpeed) * ParallaxBackground.SPEED_GROUND, height: groundHeight)
        yMid    = wrapY(yMid    - CGFloat(baseSpeed) * ParallaxBackground.SPEED_MID,    height: midHeight)
        yHigh   = wrapY(yHigh   - CGFloat(baseSpeed) * ParallaxBackground.SPEED_HIGH,   height: highHeight)
        placeTiles()
    }

    func updateStage5(scrollSpeedY: Float, dt: Float) {
        yGround = wrapY(yGround - CGFloat(scrollSpeedY * dt), height: groundHeight)
        yCanopy = wrapY(yCanopy - CGFloat(scrollSpeedY * dt) * ParallaxBackground.SPEED_S5_LAYER2, height: canopyHeight)
        placeGroundTiles(); placeCanopyTiles()
    }

    func updateStage6(scrollSpeedY: Float, dt: Float, elapsedTime: Float) {
        let t = elapsedTime
        if t < ParallaxBackground.S6_CLOUD_END                              { stage6SpeedModifier = 1.0 }
        else if t < ParallaxBackground.S6_BURN_END {
            let u = (t - ParallaxBackground.S6_CLOUD_END) / ParallaxBackground.S6_BURN_SPAN
            stage6SpeedModifier = 1.0 + u * (ParallaxBackground.S6_BURN_PEAK - 1.0)
        } else if t < ParallaxBackground.S6_ORBIT_END {
            let u = (t - ParallaxBackground.S6_BURN_END) / ParallaxBackground.S6_ORBIT_SPAN
            stage6SpeedModifier = ParallaxBackground.S6_BURN_PEAK + u * (ParallaxBackground.S6_ORBIT_FLOOR - ParallaxBackground.S6_BURN_PEAK)
        } else if t < ParallaxBackground.S6_BRAKE_END {
            let u = (t - ParallaxBackground.S6_ORBIT_END) / ParallaxBackground.S6_BRAKE_SPAN
            stage6SpeedModifier = ParallaxBackground.S6_ORBIT_FLOOR + u * (0 - ParallaxBackground.S6_ORBIT_FLOOR)
        } else { stage6SpeedModifier = 0 }
        update(baseSpeed: scrollSpeedY * stage6SpeedModifier * dt)
        yCanopy = wrapY(yCanopy - CGFloat(scrollSpeedY * 1.5 * dt), height: canopyHeight)
        placeCanopyTiles()
    }

    func resetScroll() { yGround = 0; yMid = 0; yHigh = 0; yCanopy = 0; stage6SpeedModifier = 1; placeTiles() }

    private func wrapY(_ y: CGFloat, height: CGFloat) -> CGFloat {
        if height <= 0 { return 0 }
        var v = y.truncatingRemainder(dividingBy: height)
        if v > 0 { v -= height }    // keep it negative (below 0 anchor)
        return v
    }

    private func placeTiles() { placeGroundTiles(); placeMidTiles(); placeHighTiles() }

    private func placeGroundTiles() {
        guard groundHeight > 0 else { return }
        groundA?.position = CGPoint(x: 0, y: yGround)
        groundB?.position = CGPoint(x: 0, y: yGround + groundHeight)
    }
    private func placeMidTiles() {
        guard midHeight > 0 else { return }
        midA?.position = CGPoint(x: 0, y: yMid)
        midB?.position = CGPoint(x: 0, y: yMid + midHeight)
    }
    private func placeHighTiles() {
        guard highHeight > 0 else { return }
        highA?.position = CGPoint(x: 0, y: yHigh)
        highB?.position = CGPoint(x: 0, y: yHigh + highHeight)
    }
    private func placeCanopyTiles() {
        guard canopyHeight > 0 else { return }
        canopyA?.position = CGPoint(x: 0, y: yCanopy)
        canopyB?.position = CGPoint(x: 0, y: yCanopy + canopyHeight)
    }
}
