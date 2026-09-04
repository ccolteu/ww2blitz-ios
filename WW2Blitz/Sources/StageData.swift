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
    var speedMultiplier: Float {
        switch self {
        case .monkey:   return 0.65
        case .easy:     return 0.85
        case .normal:   return 1.00
        case .hard:     return 1.15
        case .veryHard: return 1.30
        case .expert:   return 1.45
        case .hardcore: return 1.60
        }
    }
    var intervalDivider: Float {
        switch self {
        case .monkey:   return 0.75
        case .easy:     return 0.90
        case .normal:   return 1.00
        case .hard:     return 1.15
        case .veryHard: return 1.25
        case .expert:   return 1.40
        case .hardcore: return 1.55
        }
    }
    var burstBonus: Int {
        switch self {
        case .monkey:   return -1
        case .veryHard, .expert: return 1
        case .hardcore: return 2
        default:        return 0
        }
    }

    static func fromIndex(_ index: Int) -> Difficulty {
        Difficulty(rawValue: index) ?? .normal
    }
}

class StageData {
    static var liveInstance: StageData?
    /// Campaign playlist: any order, skip, or repeat stage ids (1...8).
    /// Credits roll after the last entry. Examples:
    ///   [1]              // one-stage credit
    ///   [3, 2, 6, 6]     // reorder + duplicate
    ///   [1, 2, 3, 4, 5, 6, 7, 8]  // full campaign
    static let STAGE_SEQUENCE = [1, 2, 3, 4, 5, 6, 7, 8]
    private static let RISE_SECS: Float = 48
    private static let DEATH_KEEP: Float = 0.40
    private static let SPEED_GAIN: Float = 0.22
    private static let FIRE_GAIN: Float = 0.28
    private static let LEAD_AT: Float = 0.60
    private static let KAMI_AT: Float = 0.50
    private static let REVENGE_AT: Float = 0.70
    private static let BURST_AT: Float = 0.80

    private var sequenceIndex = 0
    private var stageId = 1
    private var campaignFinishedLatch = false
    private var currentDifficulty: Difficulty = .normal
    private var combatRank: Float = 0
    private var savedContinueDip = 0

    var currentStage: Int { stageId }
    var missionNumber: Int { sequenceIndex + 1 }
    var def: StageDef { StageCatalog.get(stageId) }
    var isCampaignFinished: Bool { campaignFinishedLatch }
    var difficultyIndex: Int {
        get { currentDifficulty.index }
        set { currentDifficulty = Difficulty.fromIndex(newValue) }
    }

    var scrollSpeedY: Float = 180
    var bossAtSeconds: Float = 38

    init() {
        StageData.liveInstance = self
        resetToStart()
    }

    func getDifficulty() -> Difficulty { currentDifficulty }
    func setDifficulty(_ diff: Difficulty) { currentDifficulty = diff }

    func getContinueDip() -> Int { savedContinueDip }

    func saveContinueSetting(_ credits: Int) {
        savedContinueDip = StageData.clampContinueDip(credits)
        UserDefaults.standard.set(savedContinueDip, forKey: StageData.KEY_CONTINUE)
    }

    func loadPersistentSettings() {
        savedContinueDip = StageData.clampContinueDip(
            UserDefaults.standard.integer(forKey: StageData.KEY_CONTINUE))
    }

    static func continueDipName(_ credits: Int) -> String {
        if credits <= 0 { return "OFF" }
        if credits == 1 { return "1 CREDIT" }
        return "2 CREDITS"
    }

    private static let KEY_CONTINUE = "continue_credits"

    private static func clampContinueDip(_ value: Int) -> Int {
        if value < 0 { return 0 }
        if value > 2 { return 2 }
        return value
    }

    func resetCombatRank() { combatRank = 0 }

    func dumpCombatRankOnDeath() {
        combatRank *= StageData.DEATH_KEEP
    }

    func tickCombatRank(dt: Float, playerAtMaxWeapon: Bool) {
        if dt <= 0.0001 || !playerAtMaxWeapon { return }
        combatRank += dt / StageData.RISE_SECS
        let cap = rankCap()
        if combatRank > cap { combatRank = cap }
    }

    func shotSpeedScale() -> Float {
        currentDifficulty.speedMultiplier * (1 + StageData.SPEED_GAIN * combatRank)
    }

    func fireIntervalDivider() -> Float {
        let div = currentDifficulty.intervalDivider * (1 + StageData.FIRE_GAIN * combatRank)
        return div < 0.01 ? 0.01 : div
    }

    func burstBonus() -> Int {
        let extra = combatRank >= StageData.BURST_AT ? 1 : 0
        return currentDifficulty.burstBonus + extra
    }

    func aimSlopRad() -> Float {
        if currentDifficulty.index >= 3 { return 0 }
        return Enemy.AIM_SLOP_RAD * (1 - combatRank)
    }

    func shouldLeadShots() -> Bool {
        currentDifficulty.index >= 5 || combatRank >= StageData.LEAD_AT
    }

    func kamikazeSeeks() -> Bool {
        currentDifficulty.index >= 3 || combatRank >= StageData.KAMI_AT
    }

    func lootChanceScale() -> Float {
        switch currentDifficulty.index {
        case 1: return 0.75
        case 2: return 0.85
        case 4: return 1.08
        case 5: return 1.15
        case 6: return 1.20
        case let i where i >= 7: return 1.25
        default: return 1.0
        }
    }

    func revengeOnDeath() -> Bool {
        currentDifficulty.index >= 5 || combatRank >= StageData.REVENGE_AT
    }

    func popcornSuicide() -> Bool { currentDifficulty.index >= 3 }

    func scoreMultiplier() -> Float {
        switch currentDifficulty.index {
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

    private func rankCap() -> Float {
        switch currentDifficulty.index {
        case 1: return 0.30
        case 2: return 0.55
        default: return 1
        }
    }

    func isLastInSequence() -> Bool {
        let n = StageData.STAGE_SEQUENCE.count
        if n <= 0 { return true }
        return sequenceIndex >= n - 1
    }

    func advanceToNextStage() {
        let seq = StageData.STAGE_SEQUENCE
        let n = seq.count
        if n <= 0 {
            campaignFinishedLatch = true
            return
        }
        sequenceIndex += 1
        if sequenceIndex >= n {
            sequenceIndex = n - 1
            campaignFinishedLatch = true
            return
        }
        stageId = seq[sequenceIndex]
        applyStageMetrics(stageId)
    }

    /// Jump the playlist cursor to the first slot with this stage id (demo / attract).
    func setCurrentStage(_ stage: Int) {
        let seq = StageData.STAGE_SEQUENCE
        let n = seq.count
        if n <= 0 { return }
        campaignFinishedLatch = false
        sequenceIndex = seq.firstIndex(of: stage) ?? 0
        stageId = seq[sequenceIndex]
        applyStageMetrics(stageId)
    }

    /// Bind art/metrics to whatever the playlist cursor already points at.
    /// Does not search by id, so duplicate entries stay on their slot.
    func bindCurrentPlaylistSlot() {
        let seq = StageData.STAGE_SEQUENCE
        if seq.isEmpty { return }
        if sequenceIndex < 0 { sequenceIndex = 0 }
        if sequenceIndex >= seq.count { sequenceIndex = seq.count - 1 }
        stageId = seq[sequenceIndex]
        applyStageMetrics(stageId)
    }

    func resetToStart() {
        campaignFinishedLatch = false
        sequenceIndex = 0
        let seq = StageData.STAGE_SEQUENCE
        if seq.isEmpty {
            campaignFinishedLatch = true
            stageId = StageCatalog.all.first?.id ?? 1
        } else {
            stageId = seq[0]
        }
        applyStageMetrics(stageId)
    }

    func applyStageMetrics(_ stage: Int) {
        let d = StageCatalog.get(stage)
        scrollSpeedY = d.scrollSpeedY
        bossAtSeconds = d.bossAtSeconds
    }
}
