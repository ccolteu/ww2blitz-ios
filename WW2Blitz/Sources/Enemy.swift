import Foundation

class Enemy {
    var x: Float = 0
    var y: Float = 0
    var vx: Float = 0
    var vy: Float = 0
    var type: Int = 0
    var pattern: Int = 0
    var flightProfile: Int = 0
    var flightTime: Float = 0
    var patternDelay: Float = 0
    var aiPhase: Int = 0
    var holdTimer: Float = 0
    var weaveT: Float = 0
    var homeX: Float = 0
    var health: Int = 1
    var isActive: Bool = false
    var isRedShipAnchor: Bool = false
    var isDestroyer: Bool = false
    var isLandVehicle: Bool = false
    var isWagon: Bool = false
    var isGroundHeavy: Bool { isDestroyer || isLandVehicle || isWagon }
    var fireTimer: Float = 0
    var burstLeft: Int = 0
    var burstWait: Float = 0
    var aimVx: Float = 0
    var aimVy: Float = 0
    var deathClearBullets: Bool = false
    var diamondLeader: Bool = false
    var diamondWingSign: Float = 0
    var splinterVeer: Bool = false
    var shudderTimer: Float = 0

    func triggerMicroShudder() {
        shudderTimer = Enemy.SHUDDER_DURATION
    }

    /// Writes aimVx/aimVy toward the player.
    @discardableResult
    func writeAimedShot(targetX: Float, targetY: Float,
                        playerVelX: Float, playerVelY: Float,
                        shotSpeed: Float, applyLead: Bool, slopRad: Float) -> Bool {
        var tx = targetX
        var ty = targetY
        if applyLead {
            let odx = targetX - x
            let ody = targetY - y
            let dist = sqrtf(odx * odx + ody * ody)
            let eta = shotSpeed > 1 ? dist / shotSpeed : 0
            tx += playerVelX * eta
            ty += playerVelY * eta
        }
        let dx = tx - x
        let dy = ty - y
        let lenSq = dx * dx + dy * dy
        if lenSq <= 0.0001 { return false }
        let ang = atan2f(dy, dx) + slopRad
        aimVx = cosf(ang) * shotSpeed
        aimVy = sinf(ang) * shotSpeed
        return true
    }

    func steerToward(targetX: Float, targetY: Float, dt: Float, turnRate: Float) {
        let spdSq = vx * vx + vy * vy
        let spd: Float = spdSq > 0.0001 ? sqrtf(spdSq) : 220
        let desired = atan2f(targetY - y, targetX - x)
        let current = atan2f(vy, vx)
        var delta = desired - current
        if delta > Enemy.PI { delta -= Enemy.TWO_PI }
        if delta < -Enemy.PI { delta += Enemy.TWO_PI }
        let maxTurn = turnRate * dt
        let turn = delta > maxTurn ? maxTurn : (delta < -maxTurn ? -maxTurn : delta)
        let ang = current + turn
        vx = cosf(ang) * spd
        vy = sinf(ang) * spd
    }

    static let FLIGHT_PROFILE_SWEEP_ARC = 101
    static let SHUDDER_DURATION: Float = 0.08
    static let SHUDDER_AMPLITUDE: Float = 2.0
    static let AIM_SLOP_RAD: Float = 0.15
    static let KAMI_TURN_RATE: Float = 4.8
    static let PI: Float = 3.1415927
    static let TWO_PI: Float = 6.2831855
}
