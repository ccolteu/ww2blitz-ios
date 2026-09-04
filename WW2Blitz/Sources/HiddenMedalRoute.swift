import Foundation

/// Per-map secret medal beats. Cues are screen fractions; collect them for the recap SECRET line.
struct HiddenMedalRoute {
    private static let MAX_CUES = 5
    private static var atSec = [Float](repeating: 0, count: MAX_CUES)
    private static var xFrac = [Float](repeating: 0, count: MAX_CUES)
    private static var yFrac = [Float](repeating: 0, count: MAX_CUES)
    private static var fired = [Bool](repeating: false, count: MAX_CUES)
    private static var boundStage = -1
    private static var cueCount = 0

    static func cueCountValue() -> Int { cueCount }

    static func reset() {
        boundStage = -1
        cueCount = 0
        for i in 0..<MAX_CUES { fired[i] = false }
    }

    static func bind(_ stageId: Int) {
        if boundStage == stageId { return }
        boundStage = stageId
        cueCount = loadCues(stageId)
        for i in 0..<MAX_CUES { fired[i] = false }
    }

    static func tick(elapsed: Float, screenW: Float, screenH: Float, items: PowerUpItem) {
        var i = 0
        while i < cueCount {
            if !fired[i] && elapsed >= atSec[i] {
                fired[i] = true
                items.spawnSecretMedal(x: xFrac[i] * screenW, y: yFrac[i] * screenH)
            }
            i += 1
        }
    }

    private static func loadCues(_ stageId: Int) -> Int {
        switch stageId {
        case 1: return pack(6, 0.10, 0.08, 14, 0.90, 0.10, 22, 0.08, 0.12, 30, 0.92, 0.08, 35, 0.50, 0.06)
        case 2: return pack(5, 0.88, 0.08, 11, 0.10, 0.10, 17, 0.90, 0.08, 23, 0.12, 0.12, 28, 0.50, 0.07)
        case 3: return pack(4, 0.08, 0.08, 9, 0.92, 0.10, 14, 0.10, 0.08, 19, 0.88, 0.10, 23, 0.50, 0.06)
        case 4: return pack(7, 0.10, 0.08, 15, 0.90, 0.10, 23, 0.08, 0.08, 31, 0.92, 0.10, 38, 0.50, 0.07)
        case 5: return pack(6, 0.88, 0.08, 14, 0.10, 0.10, 22, 0.90, 0.08, 30, 0.12, 0.10, 36, 0.50, 0.07)
        case 6: return pack(8, 0.12, 0.08, 16, 0.88, 0.10, 24, 0.08, 0.08, 32, 0.92, 0.10, 40, 0.50, 0.07)
        case 7: return pack(8, 0.10, 0.08, 16, 0.90, 0.10, 24, 0.08, 0.08, 32, 0.92, 0.10, 40, 0.50, 0.07)
        case 8: return pack(1.2, 0.12, 0.10, 2.6, 0.88, 0.10, 3.8, 0.20, 0.08)
        default: return 0
        }
    }

    private static func pack(_ triples: Float...) -> Int {
        let n = min(triples.count / 3, MAX_CUES)
        var i = 0
        while i < n {
            let o = i * 3
            atSec[i] = triples[o]
            xFrac[i] = triples[o + 1]
            yFrac[i] = triples[o + 2]
            i += 1
        }
        return n
    }
}
