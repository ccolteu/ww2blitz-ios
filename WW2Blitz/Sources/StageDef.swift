import Foundation

enum BossCombatKind: Int {
    case plane = 1
    case tank = 2
    case battleship = 3
    case winter = 4
    case atoll = 5
    case jungle = 6
    case canopy = 7
    case orbit = 8
}

enum StageTheaterKind {
    case scroll, facility, ascent
}

enum StageWaveKind {
    static let CLOUD_FORTRESS = 1
    static let IRON_TREADS    = 2
    static let STEEL_ATLANTIC = 3
    static let FROZEN_FRONT   = 4
    static let CORAL_ATOLL    = 5
    static let JUNGLE_RUINS   = 6
    static let ASCENT_CANOPY  = 7
    static let ORBIT_INTRO    = 8
    static let OPERATION_WINGMAN = 1
}

struct BossWrecks {
    var triPart: Bool
}

struct StageDef {
    var id: Int
    var operationName: [Character]
    var scrollSpeedY: Float
    var bossAtSeconds: Float
    var stageMusicTrack: String
    var theaterKind: StageTheaterKind = .scroll
    var locksElapsedAtBoss: Bool = false
    var usesOpeningPowerV: Bool = false
    var hasOverlayClouds: Bool = false
    var keyedOverlayLayers: Bool = false
    var airHeavyHighHold: Bool = false
    var introOnly: Bool = false
    var introSecs: Float = 0
    var spaceSwapAt: Float = 0
    var canopyAt: Float = 0
    var midFile: String? = nil
    var highFile: String? = nil
    var canopyFile: String? = nil
    var floorAltFile: String? = nil
    var skinTankFile: String? = nil
    var skinDestroyerFile: String? = nil
    var skinWagonFile: String? = nil
    var skinHelicopterFile: String? = nil
    var waveScript: Int = 1
    var bossCombat: BossCombatKind = .plane
    var boss: BossWrecks
    var usesSharedBossEntranceCue: Bool { usesOpeningPowerV && !introOnly }

    var operationNameString: String { String(operationName) }

    func stagePath() -> String { "Stages/\(id)" }
    func floorPath() -> String { "\(stagePath())/floor.png" }
    func midPath() -> String? { midFile.map { "\(stagePath())/\($0)" } }
    func highPath() -> String? { highFile.map { "\(stagePath())/\($0)" } }
    func canopyPath() -> String? { canopyFile.map { "\(stagePath())/\($0)" } }
    func floorAltPath() -> String? { floorAltFile.map { "\(stagePath())/\($0)" } }
    func briefingPath() -> String { "\(stagePath())/briefing.png" }
    func bossBodyPath() -> String { "\(stagePath())/boss.png" }
    func wreckLeftPath() -> String { "\(stagePath())/wreck_left.png" }
    func wreckRightPath() -> String { "\(stagePath())/wreck_right.png" }
    func wreckCenterPath() -> String { "\(stagePath())/wreck_center.png" }
    func skinTankPath() -> String? { skinTankFile.map { "\(stagePath())/\($0)" } }
    func skinDestroyerPath() -> String? { skinDestroyerFile.map { "\(stagePath())/\($0)" } }
    func skinWagonPath() -> String? { skinWagonFile.map { "\(stagePath())/\($0)" } }
    func skinHelicopterPath() -> String? { skinHelicopterFile.map { "\(stagePath())/\($0)" } }
}

// MARK: - Catalog

struct StageCatalog {
    static let all: [StageDef] = buildAll()

    static func get(_ id: Int) -> StageDef {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    static func count() -> Int { all.count }
    static func maxId() -> Int { all.map(\.id).max() ?? 1 }

    private static func buildAll() -> [StageDef] {
        let wrecks = BossWrecks(triPart: false)
        let wrecksTri = BossWrecks(triPart: true)
        return [
            StageDef(
                id: 1,
                operationName: Array("CLOUD FORTRESS"),
                scrollSpeedY: 180,
                bossAtSeconds: 38,
                stageMusicTrack: SoundManager.BGM_STAGE1,
                usesOpeningPowerV: true,
                hasOverlayClouds: true,
                midFile: "mid.png",
                highFile: "high.png",
                waveScript: StageWaveKind.CLOUD_FORTRESS,
                bossCombat: .plane,
                boss: wrecks
            ),
            StageDef(
                id: 2,
                operationName: Array("IRON TREADS"),
                scrollSpeedY: 260,
                bossAtSeconds: 30,
                stageMusicTrack: SoundManager.BGM_STAGE2,
                usesOpeningPowerV: true,
                skinTankFile: "skin_tank.png",
                waveScript: StageWaveKind.IRON_TREADS,
                bossCombat: .tank,
                boss: wrecks
            ),
            StageDef(
                id: 3,
                operationName: Array("STEEL ATLANTIC"),
                scrollSpeedY: 200,
                bossAtSeconds: 42,
                stageMusicTrack: SoundManager.BGM_STAGE3,
                locksElapsedAtBoss: true,
                usesOpeningPowerV: true,
                airHeavyHighHold: true,
                skinDestroyerFile: "skin_destroyer.png",
                waveScript: StageWaveKind.STEEL_ATLANTIC,
                bossCombat: .battleship,
                boss: wrecks
            ),
            StageDef(
                id: 4,
                operationName: Array("FROZEN FRONT"),
                scrollSpeedY: 240,
                bossAtSeconds: 42,
                stageMusicTrack: SoundManager.BGM_STAGE4,
                locksElapsedAtBoss: true,
                usesOpeningPowerV: true,
                hasOverlayClouds: true,
                keyedOverlayLayers: true,
                midFile: "mid.png",
                highFile: "high.png",
                skinTankFile: "skin_tank.png",
                waveScript: StageWaveKind.FROZEN_FRONT,
                bossCombat: .winter,
                boss: wrecks
            ),
            StageDef(
                id: 5,
                operationName: Array("CORAL ATOLL"),
                scrollSpeedY: 220,
                bossAtSeconds: 40,
                stageMusicTrack: SoundManager.BGM_STAGE5,
                locksElapsedAtBoss: true,
                usesOpeningPowerV: true,
                hasOverlayClouds: true,
                keyedOverlayLayers: true,
                midFile: "mid.png",
                highFile: "high.png",
                waveScript: StageWaveKind.CORAL_ATOLL,
                bossCombat: .atoll,
                boss: wrecks
            ),
            StageDef(
                id: 6,
                operationName: Array("JUNGLE RUINS"),
                scrollSpeedY: 310,
                bossAtSeconds: 45,
                stageMusicTrack: SoundManager.BGM_STAGE6,
                locksElapsedAtBoss: true,
                usesOpeningPowerV: true,
                skinHelicopterFile: "skin_hellicopter.png",
                waveScript: StageWaveKind.JUNGLE_RUINS,
                bossCombat: .jungle,
                boss: wrecks
            ),
            StageDef(
                id: 7,
                operationName: Array("ASCENT CANOPY"),
                scrollSpeedY: 280,
                bossAtSeconds: 45,
                stageMusicTrack: SoundManager.BGM_STAGE7,
                theaterKind: .facility,
                locksElapsedAtBoss: true,
                canopyFile: "canopy.png",
                skinWagonFile: "skin_wagon.png",
                waveScript: StageWaveKind.ASCENT_CANOPY,
                bossCombat: .canopy,
                boss: wrecksTri
            ),
            StageDef(
                id: 8,
                operationName: Array("ORBIT THRESHOLD"),
                scrollSpeedY: 180,
                bossAtSeconds: 50,
                stageMusicTrack: SoundManager.BGM_STAGE8,
                theaterKind: .ascent,
                introOnly: true,
                introSecs: 5,
                spaceSwapAt: 30,
                canopyAt: 35,
                canopyFile: "canopy.png",
                floorAltFile: "floor_alt.png",
                waveScript: StageWaveKind.ORBIT_INTRO,
                bossCombat: .orbit,
                boss: wrecksTri
            ),
        ]
    }
}
