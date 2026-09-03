import Foundation

class BossComponent {
    var relOffsetX: Float = 0
    var relOffsetY: Float = 0
    var x: Float = 0
    var y: Float = 0
    var halfW: Float = 0
    var halfH: Float = 0
    var health: Int = 0
    var maxHealth: Int = 0
    var isDestroyed: Bool = false
    var componentType: Int = 0
    var shudderTimer: Float = 0

    func triggerMicroShudder() {
        shudderTimer = BossComponent.SHUDDER_DURATION
    }

    static let SHUDDER_DURATION: Float = 0.08
    static let SHUDDER_AMPLITUDE: Float = 2.0
}
