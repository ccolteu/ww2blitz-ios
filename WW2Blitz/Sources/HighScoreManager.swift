import Foundation

class HighScoreManager {
    static let shared = HighScoreManager()

    static let SLOT_COUNT = 10
    static let DIFF_TABLES = 7

    private var topScores: [Int]
    private var topNames: [String]
    private var topStages: [Int]

    private let defaults = UserDefaults.standard
    private let fallbackScores = [100000, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000]
    private let fallbackStages = [4, 3, 3, 2, 2, 1, 1, 1, 1, 1]
    private let fallbackNames  = ["PSK","STK","ACE","SHM","AAA","AAA","AAA","AAA","AAA","AAA"]

    init() {
        let n = Self.DIFF_TABLES * Self.SLOT_COUNT
        topScores = [Int](repeating: 0, count: n)
        topStages = [Int](repeating: 1, count: n)
        topNames = [String](repeating: "AAA", count: n)
        var table = 0
        while table < Self.DIFF_TABLES {
            seedTable(table)
            table += 1
        }
        load()
    }

    func scoreAt(difficulty: Int, _ i: Int) -> Int { topScores[slot(difficulty, i)] }
    func stageAt(difficulty: Int, _ i: Int) -> Int { topStages[slot(difficulty, i)] }
    func nameAt(difficulty: Int, _ i: Int) -> String { topNames[slot(difficulty, i)] }

    func rankOf(score: Int, difficulty: Int) -> Int {
        var s = score
        if s < 0 { s = 0 }
        if s > 99_999_999 { s = 99_999_999 }
        if s <= topScores[slot(difficulty, Self.SLOT_COUNT - 1)] { return -1 }
        for i in 0..<Self.SLOT_COUNT {
            if s > topScores[slot(difficulty, i)] { return i }
        }
        return -1
    }

    func insert(score: Int, stage: Int, name: String, difficulty: Int) {
        let rank = rankOf(score: score, difficulty: difficulty)
        if rank < 0 { return }
        var i = Self.SLOT_COUNT - 2
        while i >= rank {
            copyRow(difficulty, from: i, to: i + 1)
            i -= 1
        }
        let dest = slot(difficulty, rank)
        topScores[dest] = max(0, min(score, 99_999_999))
        topStages[dest] = max(0, stage)
        topNames[dest] = String(name.prefix(3)).uppercased().padded(3, "A")
        save()
    }

    private func load() {
        let normalDip = Difficulty.normal.rawValue
        let hasNewNormal = defaults.object(forKey: scoreKey(normalDip, 0)) != nil
        let hasLegacy = defaults.object(forKey: "arcade_leaderboard_catalog_v2_score_0") != nil
            || defaults.object(forKey: "arcade_leaderboard_score_0") != nil
        let migrated = !hasNewNormal && hasLegacy
        var table = 0
        while table < Self.DIFF_TABLES {
            let dip = table + 1
            var i = 0
            while i < Self.SLOT_COUNT {
                let si = slot(dip, i)
                if migrated && dip == normalDip {
                    let prefix = defaults.object(forKey: "arcade_leaderboard_catalog_v2_score_0") != nil
                        ? "arcade_leaderboard_catalog_v2_"
                        : "arcade_leaderboard_"
                    topScores[si] = intOrFallback(prefix + "score_\(i)", fallbackScores[i])
                    topStages[si] = intOrFallback(prefix + "stage_\(i)", fallbackStages[i])
                    topNames[si] = defaults.string(forKey: prefix + "name_\(i)") ?? fallbackNames[i]
                } else if defaults.object(forKey: scoreKey(dip, i)) != nil {
                    topScores[si] = defaults.integer(forKey: scoreKey(dip, i))
                    topStages[si] = defaults.integer(forKey: stageKey(dip, i))
                    topNames[si] = defaults.string(forKey: nameKey(dip, i)) ?? fallbackNames[i]
                }
                i += 1
            }
            table += 1
        }
        save()
    }

    private func intOrFallback(_ key: String, _ fallback: Int) -> Int {
        defaults.object(forKey: key) != nil ? defaults.integer(forKey: key) : fallback
    }

    private func save() {
        var table = 0
        while table < Self.DIFF_TABLES {
            let dip = table + 1
            var i = 0
            while i < Self.SLOT_COUNT {
                let si = slot(dip, i)
                defaults.set(topScores[si], forKey: scoreKey(dip, i))
                defaults.set(topStages[si], forKey: stageKey(dip, i))
                defaults.set(topNames[si], forKey: nameKey(dip, i))
                i += 1
            }
            table += 1
        }
    }

    private func seedTable(_ table: Int) {
        let dip = table + 1
        var i = 0
        while i < Self.SLOT_COUNT {
            let si = slot(dip, i)
            topScores[si] = fallbackScores[i]
            topStages[si] = fallbackStages[i]
            topNames[si] = fallbackNames[i]
            i += 1
        }
    }

    private func copyRow(_ difficulty: Int, from: Int, to: Int) {
        let src = slot(difficulty, from)
        let dst = slot(difficulty, to)
        topScores[dst] = topScores[src]
        topStages[dst] = topStages[src]
        topNames[dst] = topNames[src]
    }

    private func slot(_ difficultyIndex: Int, _ index: Int) -> Int {
        var d = difficultyIndex - 1
        if d < 0 { d = 2 }
        if d >= Self.DIFF_TABLES { d = Self.DIFF_TABLES - 1 }
        var i = index
        if i < 0 { i = 0 }
        if i >= Self.SLOT_COUNT { i = Self.SLOT_COUNT - 1 }
        return d * Self.SLOT_COUNT + i
    }

    private func scoreKey(_ dip: Int, _ i: Int) -> String { "d\(dip)_score_\(i)" }
    private func stageKey(_ dip: Int, _ i: Int) -> String { "d\(dip)_stage_\(i)" }
    private func nameKey(_ dip: Int, _ i: Int) -> String { "d\(dip)_name_\(i)" }
}

private extension String {
    func padded(_ length: Int, _ char: Character) -> String {
        if self.count >= length { return String(self.prefix(length)) }
        return self + String(repeating: char, count: length - self.count)
    }
}
