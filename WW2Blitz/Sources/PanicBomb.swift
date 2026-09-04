import SpriteKit

class PanicBomb {
    var x: Float = 0
    var y: Float = 0
    var currentFrameTime: Float = 0
    var currentFrameIndex: Int = 0
    var isActive: Bool = false

    static let FRAME_COUNT     = 6
    static let FRAME_DURATION: Float = 0.083
    static let TOTAL_DURATION: Float = Float(PanicBomb.FRAME_COUNT) * PanicBomb.FRAME_DURATION

    private var node: SKSpriteNode?
    private var frames: [SKTexture] = []
    private weak var scene: SKScene?
    /// Android y-down dest: full screen height, width from sheet aspect, centered.
    private var left: Float = 0
    private var right: Float = 0
    private var top: Float = 0
    private var bottom: Float = 0

    func setup(scene: SKScene) {
        self.scene = scene
        frames = (1...PanicBomb.FRAME_COUNT).map { GameArt.texture("Images/player_bomb_\($0)") }
        let n = SKSpriteNode(texture: frames[0])
        n.zPosition = 60; n.isHidden = true; n.alpha = 1
        scene.addChild(n)
        node = n
        layout(screenW: Float(scene.size.width), screenH: Float(scene.size.height))
    }

    func deactivate() {
        isActive = false
        node?.isHidden = true
    }

    func activate(startX: Float, startY: Float) {
        x = startX; y = startY
        currentFrameTime = 0; currentFrameIndex = 0; isActive = true
        if let scene = scene {
            layout(screenW: Float(scene.size.width), screenH: Float(scene.size.height))
        }
    }

    func update(dt: Float, screenW: Float, screenH: Float) {
        guard isActive, let node = node else { return }
        currentFrameTime += dt
        if currentFrameTime >= PanicBomb.FRAME_DURATION {
            currentFrameTime = 0
            currentFrameIndex += 1
        }
        if currentFrameIndex >= PanicBomb.FRAME_COUNT {
            isActive = false; node.isHidden = true; return
        }
        layout(screenW: screenW, screenH: screenH)
        node.texture = frames[min(currentFrameIndex, frames.count - 1)]
        node.size = CGSize(width: CGFloat(right - left), height: CGFloat(bottom - top))
        node.position = CGPoint(
            x: CGFloat((left + right) * 0.5),
            y: CGFloat(screenH - (top + bottom) * 0.5)
        )
        node.isHidden = false
    }

    /// Android `bombDstRect` in y-down world space.
    func worldRect() -> (left: Float, top: Float, right: Float, bottom: Float) {
        (left, top, right, bottom)
    }

    private func layout(screenW: Float, screenH: Float) {
        let tex = frames.first
        let bmpW = Float(tex?.size().width ?? 1024)
        let bmpH = Float(tex?.size().height ?? 1536)
        let inverseAspect = bmpW / max(bmpH, 1)
        let targetH = screenH
        let targetW = targetH * inverseAspect
        let leftOffset = (screenW - targetW) * 0.5
        left = leftOffset
        right = leftOffset + targetW
        top = 0
        bottom = screenH
    }
}
