import Foundation

class HighScoreManager {
    static let shared = HighScoreManager()

    static let SLOT_COUNT = 10
    private(set) var topScores:  [Int]
    private(set) var topNames:   [String]
    private(set) var topStages:  [Int]

    private let defaults = UserDefaults.standard
    /// Isolated from pre-reindex `arcade_leaderboard_` rows (those stage numbers are the old catalog).
    private let kPrefix = "arcade_leaderboard_catalog_v2_"

    private let fallbackScores = [100000, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000]
    private let fallbackStages = [4, 3, 3, 2, 2, 1, 1, 1, 1, 1]
    private let fallbackNames  = ["PSK","STK","ACE","SHM","AAA","AAA","AAA","AAA","AAA","AAA"]

    init() {
        topScores = fallbackScores
        topStages = fallbackStages
        topNames  = fallbackNames
        load()
    }

    func scoreAt(_ i: Int) -> Int  { topScores[i] }
    func stageAt(_ i: Int) -> Int  { topStages[i] }
    func nameAt(_ i: Int)  -> String { topNames[i] }

    /// Returns insertion index if the score qualifies (0-based), or -1 if not.
    func rankOf(score: Int) -> Int {
        for i in 0..<Self.SLOT_COUNT { if score > topScores[i] { return i } }
        return -1
    }

    func insert(score: Int, stage: Int, name: String) {
        let rank = rankOf(score: score)
        if rank < 0 { return }
        topScores.insert(score, at: rank); topScores.removeLast()
        topStages.insert(stage, at: rank); topStages.removeLast()
        topNames.insert(String(name.prefix(3)).uppercased().padded(3, "A"), at: rank)
        topNames.removeLast()
        save()
    }

    private func save() {
            for i in 0..<Self.SLOT_COUNT {
            defaults.set(topScores[i], forKey: kPrefix + "score_\(i)")
            defaults.set(topStages[i], forKey: kPrefix + "stage_\(i)")
            defaults.set(topNames[i],  forKey: kPrefix + "name_\(i)")
        }
    }
    private func load() {
        var anyStored = false
            for i in 0..<Self.SLOT_COUNT {
            let k = kPrefix + "score_\(i)"
            if defaults.object(forKey: k) != nil {
                anyStored = true
                topScores[i] = defaults.integer(forKey: k)
                topStages[i] = defaults.integer(forKey: kPrefix + "stage_\(i)")
                topNames[i]  = defaults.string(forKey: kPrefix + "name_\(i)") ?? fallbackNames[i]
            }
        }
    }
}

private extension String {
    func padded(_ length: Int, _ char: Character) -> String {
        if self.count >= length { return String(self.prefix(length)) }
        return self + String(repeating: char, count: length - self.count)
    }
}
