import Foundation

class EnemyBullet {
    var x: Float = 0
    var y: Float = 0
    var vx: Float = 0
    var vy: Float = 0
    var isActive: Bool = false
    var flags: Int = 0

    static let FLAG_GRAZED = 1
    static let FLAG_PINK   = 2
    static let FLAG_LASER  = 4
    static let FLAG_CYAN   = 8
}
