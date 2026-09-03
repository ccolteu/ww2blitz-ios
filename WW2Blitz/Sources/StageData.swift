import Foundation

enum Difficulty: Int, CaseIterable {
    case monkey   = 1
    case easy     = 2
    case normal   = 3
    case hard     = 4
    case veryHard = 5
    case expert   = 6
    case hardcore = 7

    var displayName: String {
        switch self {
        case .monkey:   return "MONKEY"
        case .easy:     return "EASY"
        case .normal:   return "NORMAL"
        case .hard:     return "HARD"
        case .veryHard: return "VERY HARD"
        case .expert:   return "EXPERT"
        case .hardcore: return "HARDCORE"
        }
    }

    var index: Int { rawValue }
}

class StageData {
    static var liveInstance: StageData?

    var currentStage: Int = 1
    var def: StageDef { StageCatalog.get(currentStage) }
    var difficultyIndex: Int = 3  // NORMAL
    var combatRank: Float = 0     // 0.0 – 1.0

    var scrollSpeedY: Float = 200
    var bossAtSeconds: Float = 30

    // --- Difficulty scaling helpers ---
    func shotSpeedScale() -> Float {
        switch difficultyIndex {
        case 1: return 0.65
        case 2: return 0.80
        case 3: return 1.00
        case 4: return 1.15
        case 5: return 1.30
        case 6: return 1.50
        case 7: return 1.80
        default: return 1.00
        }
    }

    func fireIntervalDivider() -> Float {
        let base: Float
        switch difficultyIndex {
        case 1: return 0.65
        case 2: return 0.80
        case 3: return 1.00
        case 4: return 1.15
        case 5: return 1.30
        case 6: return 1.55
        case 7: return 2.00
        default: return 1.00
        }
        return base
    }

    func aimSlopRad() -> Float {
        let base: Float
        switch difficultyIndex {
        case 1: return Enemy.AIM_SLOP_RAD * 2.0
        case 2: return Enemy.AIM_SLOP_RAD * 1.4
        case 3: return Enemy.AIM_SLOP_RAD
        case 4: return Enemy.AIM_SLOP_RAD * 0.6
        case 5: return Enemy.AIM_SLOP_RAD * 0.3
        case 6, 7: return 0
        default: return Enemy.AIM_SLOP_RAD
        }
        return base
    }

    func shouldLeadShots() -> Bool { difficultyIndex >= 5 }

    func burstBonus() -> Int {
        switch difficultyIndex {
        case 6: return 1
        case 7: return 2
        default: return 0
        }
    }

    func kamikazeSeeks() -> Bool { difficultyIndex >= 4 }

    func lootChanceScale() -> Float {
        switch difficultyIndex {
        case 1: return 0.75
        case 2: return 0.85
        case 4: return 1.08
        case 5: return 1.15
        case 6: return 1.20
        case 7: return 1.25
        default: return 1.0
        }
    }

    func scoreMultiplier() -> Float {
        switch difficultyIndex {
        case 1: return 0.5
        case 2: return 0.8
        case 3: return 1.0
        case 4: return 1.2
        case 5: return 1.5
        case 6: return 2.0
        case 7: return 3.0
        default: return 1.0
        }
    }

    func dumpCombatRankOnDeath() {
        combatRank = max(0, combatRank - 0.4)
    }

    func tickCombatRank(dt: Float, playerAtMaxWeapon: Bool) {
        if playerAtMaxWeapon {
            combatRank = min(1.0, combatRank + dt * 0.015)
        } else {
            combatRank = max(0, combatRank - dt * 0.008)
        }
    }
}
