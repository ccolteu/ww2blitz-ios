import Foundation

class ScoreManager {
    static let instance = ScoreManager()

    private var score: Int = 0
    private var grazeCount: Int = 0
    private var recapPhase: Int = PHASE_IDLE
    private var recapTimer: Float = 0
    private var recapFrame: Int = 0
    private var livesCount: Int = 0
    private var bombsCount: Int = 0
    private var livesBonusTarget: Int = 0
    private var bombsBonusTarget: Int = 0
    private var grazeBonusTarget: Int = 0
    private var livesAwarded: Int = 0
    private var bombsAwarded: Int = 0
    private var grazeAwarded: Int = 0
    private var recapActive: Bool = false
    private var activeMultiplier: Float = 1.0
    private var nextExtendAt: Int = ScoreManager.EXTEND_FIRST
    private var pendingExtends: Int = 0
    private var extendsArmed: Bool = false

    // popup queue
    private var popX = [Float](repeating: 0, count: ScoreManager.POPUP_SLOTS)
    private var popY = [Float](repeating: 0, count: ScoreManager.POPUP_SLOTS)
    private var popV = [Int](repeating: 0, count: ScoreManager.POPUP_SLOTS)
    private var popupCount: Int = 0

    func getScore() -> Int { score }
    func setScore(_ value: Int) {
        var next = value
        if next < 0 { next = 0 }
        if next > Self.MAX_SCORE { next = Self.MAX_SCORE }
        score = next
    }
    func addScore(_ points: Int) {
        if points <= 0 { return }
        let before = score
        setScore(score + points)
        latchExtends(before: before, after: score)
    }
    func armExtends() { extendsArmed = true }
    func consumeExtend() -> Bool {
        if pendingExtends <= 0 { return false }
        pendingExtends -= 1
        return true
    }
    func syncDifficultyMultiplier(_ difficultyIndex: Int) {
        activeMultiplier = [1: 0.5, 2: 0.8, 3: 1.0, 4: 1.2, 5: 1.5, 6: 2.0, 7: 3.0][difficultyIndex] ?? 1.0
    }
    func scalePoints(_ base: Int) -> Int {
        var v = Int(Float(base) * activeMultiplier)
        if v < 0 { v = 0 }
        if v > Self.MAX_SCORE { v = Self.MAX_SCORE }
        return v
    }
    func addFlankBreakBonus(x: Float, y: Float) {
        let awarded = scalePoints(Self.FLANK_BREAK_POINTS)
        addScore(awarded)
        queuePopup(x: x, y: y, value: awarded)
    }
    func addCoreKillBonus(x: Float, y: Float) {
        let awarded = scalePoints(Self.CORE_KILL_POINTS)
        addScore(awarded)
        queuePopup(x: x, y: y, value: awarded)
    }
    func addBulletCancelBonus(x: Float, y: Float) {
        let awarded = scalePoints(Self.BULLET_CANCEL_POINTS)
        addScore(awarded)
        queuePopup(x: x, y: y, value: awarded)
    }
    func hasPopup() -> Bool { popupCount > 0 }
    func popupX() -> Float { popupCount > 0 ? popX[0] : 0 }
    func popupY() -> Float { popupCount > 0 ? popY[0] : 0 }
    func popupValue() -> Int { popupCount > 0 ? popV[0] : 0 }
    func consumePopup() {
        if popupCount <= 0 { return }
        for i in 0..<(popupCount - 1) {
            popX[i] = popX[i+1]; popY[i] = popY[i+1]; popV[i] = popV[i+1]
        }
        popupCount -= 1
    }
    func addGrazeScore(_ points: Int) {
        grazeCount = min(grazeCount + 1, Self.MAX_GRAZE)
        addScore(scalePoints(points))
    }
    func getGrazeCount() -> Int { grazeCount }
    func recapPhaseValue() -> Int { recapPhase }
    func recapFrameValue() -> Int { recapFrame }
    func recapLivesCount() -> Int { livesCount }
    func recapBombsCount() -> Int { bombsCount }
    func recapGrazeCount() -> Int { grazeCount }
    func recapLivesAwarded() -> Int { livesAwarded }
    func recapBombsAwarded() -> Int { bombsAwarded }
    func recapGrazeAwarded() -> Int { grazeAwarded }
    func recapBonusTotal() -> Int {
        max(0, min(livesBonusTarget + bombsBonusTarget + grazeBonusTarget, Self.MAX_SCORE))
    }
    func isRecapReady() -> Bool { recapActive && recapPhase == ScoreManager.PHASE_TOTAL }
    func beginRecap(remainingLives: Int, remainingBombs: Int) {
        livesCount  = max(0, remainingLives)
        bombsCount  = max(0, remainingBombs)
        livesBonusTarget = livesCount * Self.LIFE_BONUS
        bombsBonusTarget = bombsCount * Self.BOMB_BONUS
        grazeBonusTarget = grazeCount * Self.GRAZE_BONUS
        livesAwarded = 0; bombsAwarded = 0; grazeAwarded = 0
        recapPhase = ScoreManager.PHASE_LIVES
        recapTimer = 0; recapFrame = 0; recapActive = true
    }
    func updateRecap(dt: Float) {
        if !recapActive { return }
        recapTimer += dt; recapFrame += 1
        if recapPhase == ScoreManager.PHASE_LIVES {
            tickPhase(target: livesBonusTarget, which: 0)
            if recapTimer >= Self.PHASE_DUR { snapPhase(0); recapPhase = ScoreManager.PHASE_BOMBS; recapTimer = 0 }
        } else if recapPhase == ScoreManager.PHASE_BOMBS {
            tickPhase(target: bombsBonusTarget, which: 1)
            if recapTimer >= Self.PHASE_DUR { snapPhase(1); recapPhase = ScoreManager.PHASE_GRAZE; recapTimer = 0 }
        } else if recapPhase == ScoreManager.PHASE_GRAZE {
            tickPhase(target: grazeBonusTarget, which: 2)
            if recapTimer >= Self.PHASE_DUR { snapPhase(2); recapPhase = ScoreManager.PHASE_TOTAL; recapTimer = 0 }
        }
    }
    func resetStageCounters() {
        grazeCount = 0; recapPhase = Self.PHASE_IDLE; recapTimer = 0; recapFrame = 0
        livesCount = 0; bombsCount = 0
        livesBonusTarget = 0; bombsBonusTarget = 0; grazeBonusTarget = 0
        livesAwarded = 0; bombsAwarded = 0; grazeAwarded = 0
        recapActive = false
    }
    func reset() {
        score = 0; popupCount = 0
        nextExtendAt = Self.EXTEND_FIRST; pendingExtends = 0; extendsArmed = false
        resetStageCounters()
    }

    private func latchExtends(before: Int, after: Int) {
        if !extendsArmed { return }
        var threshold = nextExtendAt
        if threshold <= 0 { return }
        while threshold > 0 && before < threshold && after >= threshold {
            pendingExtends += 1
            let next = threshold + Self.EXTEND_STEP
            if next <= threshold || next > Self.MAX_SCORE { nextExtendAt = 0; break }
            nextExtendAt = next; threshold = next
        }
    }
    private func tickPhase(target: Int, which: Int) {
        let awarded = awardedOf(which)
        var want: Int
        if recapTimer >= Self.TALLY_DUR || target <= 0 {
            want = target
        } else {
            want = min(Int(Float(target) * (recapTimer / Self.TALLY_DUR)), target)
        }
        let delta = want - awarded
        if delta > 0 { addScore(delta); setAwarded(which, want) }
        if target > 0 && awardedOf(which) < target && (recapFrame % Self.CLICK_EVERY_FRAMES) == 0 {
            SoundManager.instance.playSFX(SoundManager.SFX_PICKUP)
        }
    }
    private func snapPhase(_ which: Int) {
        let target = which == 0 ? livesBonusTarget : (which == 1 ? bombsBonusTarget : grazeBonusTarget)
        let delta = target - awardedOf(which)
        if delta > 0 { addScore(delta); setAwarded(which, target) }
    }
    private func awardedOf(_ which: Int) -> Int {
        which == 0 ? livesAwarded : (which == 1 ? bombsAwarded : grazeAwarded)
    }
    private func setAwarded(_ which: Int, _ value: Int) {
        if which == 0 { livesAwarded = value }
        else if which == 1 { bombsAwarded = value }
        else { grazeAwarded = value }
    }
    private func queuePopup(x: Float, y: Float, value: Int) {
        if popupCount >= Self.POPUP_SLOTS { return }
        popX[popupCount] = x; popY[popupCount] = y; popV[popupCount] = value
        popupCount += 1
    }

    static let GRAZE_POINTS        = 100
    static let BULLET_CANCEL_POINTS = 100
    static let FLANK_BREAK_POINTS  = 25_000
    static let CORE_KILL_POINTS    = 100_000
    static let LIFE_BONUS  = 50_000
    static let BOMB_BONUS  = 20_000
    static let GRAZE_BONUS = 500
    static let EXTEND_FIRST = 50_000
    static let EXTEND_STEP  = 100_000
    static let PHASE_IDLE  = -1
    static let PHASE_LIVES = 0
    static let PHASE_BOMBS = 1
    static let PHASE_GRAZE = 2
    static let PHASE_TOTAL = 3
    private static let PHASE_DUR: Float = 1.5
    private static let TALLY_DUR: Float = 1.0
    private static let CLICK_EVERY_FRAMES = 5
    private static let MAX_SCORE   = 99_999_999
    private static let MAX_GRAZE   = 99_999
    private static let POPUP_SLOTS = 48
}
